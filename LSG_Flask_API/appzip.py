import zipfile
import os

def create_zip_archive(directory, archive_name, files):
    with zipfile.ZipFile(archive_name, 'w', zipfile.ZIP_DEFLATED) as archive:
        for file in files:
            file_path = os.path.join(directory, file)
            if os.path.isdir(file_path):
                for root, dirs, files in os.walk(file_path):
                    for f in files:
                        f_path = os.path.join(root, f)
                        archive_path = os.path.relpath(f_path, directory)
                        archive.write(f_path, archive_path)
            else:
                archive_path = os.path.relpath(file_path, directory)
                archive.write(file_path, archive_path)

directory = '/Users/aaronbastian/Documents/Godot_Code/LiveStreamGamez.nosync/LSG_Flask_API/'
archive_name = 'app.zip'
files = [".ebextensions/", "application.py", "requirements.txt"]

create_zip_archive(directory, archive_name, files)
