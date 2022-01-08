import requests
import zipfile
import os
from datetime import date
from progressbar import progress_bar_download


def remove_files(starts_or_ends, with_str):
    if starts_or_ends == "s":
        for old_file in os.listdir('.'):
            if old_file.startswith(with_str):
                os.remove(os.path.join(".", old_file))
                print(f'Removed file {old_file}')
    elif starts_or_ends == "e":
        for old_file in os.listdir('.'):
            if old_file.endswith(with_str):
                os.remove(os.path.join(".", old_file))
                print(f'Removed file {old_file}')


remove_files("e", ".zip")
public = 'https://www.worldcubeassociation.org/results/misc/WCA_export.sql.zip'
dev = 'https://www.worldcubeassociation.org/wst/wca-developer-database-dump.zip'

databaseSelect = input('p for public, d for dev ')
if databaseSelect == 'p':
    downloadPath = public
    sqlname = f'public_export_{date.today()}.sql'
    zipname = f'public_export_{date.today()}.zip'
    remove_files('s', 'public_export')
elif databaseSelect == 'd':
    downloadPath = dev
    sqlname = f'developer_export_{date.today()}.sql'
    zipname = f'developer_export_{date.today()}.zip'
    remove_files('s', 'developer_export')

r = requests.get(downloadPath, stream=True)


print('Starting download (type: ' + r.headers.get('content-type') + ')')
progress_bar_download(downloadPath, zipname)

print('Extracting files')
with zipfile.ZipFile(zipname, 'r') as zip_ref:
    zip_ref.extractall('.')
if databaseSelect == 'p':
    os.rename('WCA_export.sql', sqlname)
    remove_files('s', 'metadata')
    remove_files('s', 'README')
    remove_files('e', '.zip')
elif databaseSelect == 'd':
    os.rename('wca-developer-database-dump.sql', sqlname)
    remove_files('e', '.zip')
print('Done')


