#!/usr/bin/python3
# -- coding: utf-8 --

# pip3 install requests
import json
import os
from pprint import pprint
import sys
import requests


class FeishuApp(object):
    def __init__(self):
        self.app_id = "cli_a2db93a761b8500d"
        self.app_secret = "i4hEOxQAPmBL0eaZzjR1Ym1aieSfL3Pq"
        self.auth_token_url = 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal'
        self.bitable_token = "bascnFsOPkWY3bwFHGIsePCAuXb"
        self.bitable_get_tables_url = "https://open.feishu.cn/open-apis/bitable/v1/apps/:app_token/tables"
        self.media_url = "https://open.feishu.cn/open-apis/drive/v1/medias/upload_all"
        self.bitable_records_url = "https://open.feishu.cn/open-apis/bitable/v1/apps/:app_token/tables/:table_id/records"

        self.tableName_to_tableId = {}
        self.prepare()

    def check_resp(self, resp):
        if resp.status_code not in [200, 201]:
            print(resp.text)
            exit
        if resp.json().get('msg') != 'success':
            print("@@@@@@@@@@@@@ "+resp.json().get('msg'))
            return False
        return True

    def get_auth_token(self):
        app_data = {"app_id": self.app_id, "app_secret": self.app_secret}
        resp = requests.post(self.auth_token_url, data=app_data)
        self.check_resp(resp)
        return resp.json()['tenant_access_token']

    def get_bitable_info(self):
        print("2. get bitable info")
        auth_str = "Bearer %s" % self.get_auth_token()
        headers = {"Authorization": auth_str}
        talbles_url = self.bitable_get_tables_url.replace(
            ':app_token', self.bitable_token)
        resp = requests.get(talbles_url, headers=headers)
        self.check_resp(resp)
        tables = resp.json()

        self.tableName_to_tableId = {
            i['name']: i['table_id'] for i in tables['data']['items']}
        print(self.tableName_to_tableId)

    def prepare(self):
        self.get_bitable_info()

    def upload_ckb(self, result_file, runtime_log_file='', note_file='', html_file=''):
        doris_version = ''
        relative_to_total = ''
        relative_to_mechine = ''
        detail = []
        if os.path.exists(result_file):
            with open(result_file, 'r') as f:
                line = f.readline()
                if line.startswith('Doris version'):
                    doris_version = line.split(':')[1].strip()
                line = f.readline()
                if line.startswith('Relative time(to total'):
                    relative_to_total = line.split(':')[1].strip()
                line = f.readline()
                if line.startswith('Relative time(to machine'):
                    relative_to_mechine = line.split(':')[1].strip()
        print([doris_version, relative_to_total, relative_to_mechine])
        if not all([doris_version, relative_to_total, relative_to_mechine]):
            print('parse result file failed!!!!')
            return False

        table_name = 'ClickBenck_aws'
        table_id = self.tableName_to_tableId[table_name]
        print("last. add new record to %s" % table_name)
        post_file_headers = {"Authorization": "Bearer %s" %
                             self.get_auth_token()}
        files = {
            'file_name': (None, result_file),
            'parent_type': (None, 'bitable_file'),
            'parent_node': (None, self.bitable_token),
            'size': (None, os.path.getsize(result_file)),
            'file': open(result_file, 'rb'),
        }
        resp = requests.post(
            self.media_url, headers=post_file_headers, files=files)
        print('post result_file')
        self.check_resp(resp)
        # pprint(resp.json())
        result_file_token = resp.json()['data']['file_token']
        detail.append({'file_token': result_file_token})
    
        runtime_file_token = ''
        if runtime_log_file:
            files = {
                'file_name': (None, runtime_log_file),
                'parent_type': (None, 'bitable_file'),
                'parent_node': (None, self.bitable_token),
                'size': (None, os.path.getsize(runtime_log_file)),
                'file': open(runtime_log_file, 'rb'),
            }
            resp = requests.post(
                self.media_url, headers=post_file_headers, files=files)
            print('post runtime_log_file')
            self.check_resp(resp)
            # pprint(resp.json())
            runtime_file_token = resp.json()['data']['file_token']
            detail.append({'file_token': runtime_file_token})
        
        html_file_token=''
        if html_file:
            files = {
                'file_name': (None, html_file),
                'parent_type': (None, 'bitable_file'),
                'parent_node': (None, self.bitable_token),
                'size': (None, os.path.getsize(html_file)),
                'file': open(html_file, 'rb'),
            }
            resp = requests.post(
                self.media_url, headers=post_file_headers, files=files)
            print('post html_file')
            self.check_resp(resp)
            # pprint(resp.json())
            html_file_token = resp.json()['data']['file_token']
            detail.append({'file_token': html_file_token})

        url = self.bitable_records_url.replace(
            ':app_token', self.bitable_token).replace(":table_id", table_id)
        note_file_str = ''
        if note_file:
            note_file_str = open(note_file, 'r').read()
        new_record_data = {
            'fields': {
                'doris-version': doris_version.strip(),
                'Relative time(to total)': float(relative_to_total),
                'Relative time(to machine)': float(relative_to_mechine),
                'detail': detail,
                'commit': 'https://github.com/apache/doris/commit/' + doris_version.strip().split('-')[1],
                'note': note_file_str
            }
        }
        print('will add record: ')
        pprint(new_record_data)
        post_headers = {"Authorization": "Bearer %s" % self.get_auth_token(),
                        "Content-Type": "application/json; charset=utf-8"}
        resp = requests.post(url, headers=post_headers,
                             data=json.dumps(new_record_data))
        print('add record to table')
        self.check_resp(resp)
        pprint(resp.json())

        return True


def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    app = FeishuApp()
    result_file = sys.argv[1]
    runtime_log_file = ''
    note_file = ''
    html_file = ''
    if len(sys.argv) > 2:
        runtime_log_file = sys.argv[2]
    if len(sys.argv) > 3:
        note_file = sys.argv[3]
    if len(sys.argv) > 4:
        html_file = sys.argv[4]
    if app.upload_ckb(result_file, runtime_log_file, note_file, html_file):
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
