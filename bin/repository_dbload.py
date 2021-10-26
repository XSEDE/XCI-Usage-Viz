#!/soft/XCI-Usage-Viz/python/bin/python3

import argparse
import csv
import datetime
from datetime import datetime, tzinfo, timedelta
import fnmatch
import gzip
import json
import logging
import logging.handlers
import os
from pid import PidFile, PidFileError
import re
import subprocess
import sys
import uuid
import pdb
from stat import *

class UTC(tzinfo):
    def utcoffset(self, dt):
        return timedelta(0)
    def tzname(self, dt):
        return 'UTC'
    def dst(self, dt):
        return timedelta(0)
utc = UTC()

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class RepositoryProcess():
    def __init__(self):
        self.target = {}
        default_source = 'postgresql://localhost:5432/usage_db'
    
        parser = argparse.ArgumentParser()
        parser.add_argument('-c', '--config', action='store', default='./repository_dbload.conf', \
                            help='Configuration file default=./repository_dbload.conf')
        parser.add_argument('-l', '--log', action='store', \
                            help='Logging level (default=warning)')
        parser.add_argument('--verbose', action='store_true', \
                            help='Verbose output')
        parser.add_argument('--pdb', action='store_true', \
                            help='Run with Python debugger')
        self.args = parser.parse_args()

        if self.args.pdb:
            pdb.set_trace()

        config_path = os.path.abspath(self.args.config)
        try:
            with open(config_path, 'r') as cf:
                self.config = json.load(cf)
        except ValueError as e:
            eprint('ERROR "{}" parsing config={}'.format(e, config_path))
            sys.exit(1)

        if self.config.get('PID_FILE'):
            self.pidfile_path = self.config['PID_FILE']
        else:   # Only one program may run per status file
            self.pidfile_path = self.config['file_status_file'] + '.pid'

    def Setup_Logging(self):
        # Initialize logging from arguments, or config file, or default to WARNING as last resort
        numeric_log = None
        if self.args.log is not None:
            numeric_log = getattr(logging, self.args.log.upper(), None)
        if numeric_log is None and 'LOG_LEVEL' in self.config:
            numeric_log = getattr(logging, self.config['LOG_LEVEL'].upper(), None)
        if numeric_log is None:
            numeric_log = getattr(logging, 'WARNING', None)
        if not isinstance(numeric_log, int):
            raise ValueError('Invalid log level: {}'.format(numeric_log))

        self.formatter = logging.Formatter(fmt='%(asctime)s.%(msecs)03d %(levelname)s %(message)s', datefmt='%Y/%m/%d %H:%M:%S')
        self.formatter_raw = logging.Formatter(fmt='%(message)s')

        self.logger = logging.getLogger('DaemonLog')
        self.logger.setLevel(numeric_log)
        self.handler = logging.handlers.TimedRotatingFileHandler(self.config['LOG_FILE'], when='W6', backupCount=999, utc=True)
        self.handler.setFormatter(self.formatter)
        self.logger.addHandler(self.handler)

        # For database loader subprocess that may stream log entries to stdout
        self.logger_raw = logging.getLogger('DaemonLogRaw')
        self.handler_raw = logging.handlers.TimedRotatingFileHandler(self.config['LOG_FILE'], when='W6', backupCount=999, utc=True)
        self.handler_raw.setFormatter(self.formatter_raw)
        self.logger_raw.addHandler(self.handler_raw)

    def Setup(self):
        for c in ['file_status_file', 'source_dir']:
            if not self.config.get(c, None):
                self.logger.error('Missing config "{}"'.format(c))
                sys.exit(1)

        try:
            with open(self.config['file_status_file']) as fh:
                self.FILE_STATUS = json.load(fh)
        except IOError as e:
            self.logger.warning('IOError loading={}, initializing'.format(self.config['file_status_file']))
            self.FILE_STATUS = {}
        except json.JSONDecodeError(msg, doc, pos):
            self.logger.error('JSONDecodeError "{}", in "{}" at "{}", QUITTING'.format(msg, doc, pos))
            self.exit(1)

        self.STEPS = {}
        step_re = re.compile('^step.(\d+)$', re.IGNORECASE)
        for c in self.config:
            c_match = step_re.match(c)
            if not c_match:
                continue
            self.STEPS[int(c_match.group(1))] = self.config[c]
            
        print_steps = []
        for s in sorted(self.STEPS):
            print_steps.append(self.STEPS[s].split()[0])
        self.logger.debug('Steps: {}'.format(' | '.join(print_steps)))

        self.stats = {
            'skipped': 0,
            'errors': 0,
            'processed': 0,
            'entries': 0
        }

        SOURCE_DIR = self.config.get('source_dir', None)
        if not os.path.isdir(SOURCE_DIR):
            self.logger.error('ERROR config source_dir={} is not a directory'.format(SOURCE_DIR))
            sys.exit(1)
        SOURCE_GLOB = self.config.get('source_glob', '*')
        files = [f for f in fnmatch.filter(os.listdir(SOURCE_DIR), SOURCE_GLOB) if os.path.isfile(os.path.join(SOURCE_DIR, f))]
        if len(files) == 0:
            self.logger.warning('WARNING no files in source_dir={} match source_glob={}'.format(SOURCE_DIR, SOURCE_GLOB))
            sys.exit(1)

        self.FILES = {}
        for f in files:
            self.FILES[f] = os.path.join(SOURCE_DIR, f)

    def process_file(self, file_name, file_fqn):
        this_history = self.FILE_STATUS.get(file_fqn, {})
        input_stat = os.stat(file_fqn)
        input_mtime_str = str(datetime.fromtimestamp(input_stat.st_mtime))
        if input_stat.st_size == this_history.get('in_size', None) \
                and input_mtime_str == this_history.get('in_mtime', None) \
                and (this_history.get('output_status') or '') == '0':
            self.stats['skipped'] += 1
            return

        this_history['in_size'] = input_stat.st_size
        this_history['in_mtime'] = input_mtime_str
        this_history['batch'] = str(uuid.uuid3(uuid.NAMESPACE_URL, file_fqn))
        self.logger.info("Processing {} mtime={} size={}".format(file_name, input_mtime_str, input_stat.st_size))

        sp = {}     # Sub-process dictionary by index=1,2,..
        for stepidx in sorted(self.STEPS):
            cmdlist = self.STEPS[stepidx].replace('%BATCH%', this_history['batch']).split()
            if stepidx == 1:
                cmdlist.append(file_fqn)
                sp[stepidx] = subprocess.Popen(cmdlist, bufsize=1, stdout=subprocess.PIPE)
            else:
                sp[stepidx] = subprocess.Popen(cmdlist, bufsize=1, stdin=sp[stepidx-1].stdout, stdout=subprocess.PIPE)
            if self.args.verbose:
                self.logger.debug('Step.{}: {}'.format(stepidx, ' '.join(cmdlist)))
            last_stdout = sp[stepidx].stdout
                
        try:
            re_rows = re.compile('^ROWS:\s*(\d+)$', re.IGNORECASE)
            re_status = re.compile('^STATUS:\s*(\w+)$', re.IGNORECASE)
            for rawline in iter(last_stdout):
                line = rawline.decode('UTF-8')
                match_rows = re_rows.match(line)
                if match_rows:
                    this_history['output_rows'] = match_rows.group(1)
                    continue
                match_status = re_status.match(line)
                if match_status:
                    this_history['output_status'] = match_status.group(1)
                    continue
                self.logger_raw.critical(line.rstrip())
        except subprocess.CalledProcessError as e:
            self.logger.error('Raised "{}" by command pipe'.format(e))
            self.stats['errors'] += 1
        else:
            status = this_history.get('output_status')
            if not status or status != '0':
                self.logger.error('File {} returned status "{}"'.format(file_name, status or 'NONE'))
                self.stats['errors'] += 1
            else:
                self.stats['processed'] += 1
 
        this_history['output_datetime'] = datetime.now(utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        self.FILE_STATUS[file_fqn] = this_history
        self.save_status()

    def save_status(self):
        try:
            with open(self.config['file_status_file'], 'w+') as file:
                json.dump(self.FILE_STATUS, file, indent=4, sort_keys=True)
        except IOError:
            self.logger.error('Failed to write status=' + self.config['file_status_file'])
            sys.exit(1)

    def exit(self, rc = 0):
        sys.exit(rc)

if __name__ == '__main__':
    start_utc = datetime.now(utc)
    process = RepositoryProcess()
    process.Setup_Logging()
    try:
        with PidFile(process.pidfile_path):
            process.Setup()
            for file in sorted(process.FILES):
                rc = process.process_file(file, process.FILES[file])
    except PidFileError:
        process.logger.critical('Pidfile lock error: {}'.format(process.pidfile_path))
        process.exit(1)
    end_utc = datetime.now(utc)
    process.logger.info("Processed files={}, seconds={}, skipped={}, errors={}".format(
        process.stats['processed'], (end_utc - start_utc).total_seconds(), 
        process.stats['skipped'], process.stats['errors']))
    process.exit(0)
