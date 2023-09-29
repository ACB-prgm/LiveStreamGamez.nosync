import subprocess
import zipfile
import sys
import os


DIRECTORY = "/Users/aaronbastian/Documents/Godot_Code/LiveStreamGamez.nosync/LSG_Flask_API"
ARCHIVE_NAME = 'app.zip'
FILES = ["application.py", "requirements.txt"]
PIP_PATH = os.path.join(sys.prefix, "bin", "pip3")


def main() -> None:
    freeze_requirements(PIP_PATH)
    create_zip_archive(DIRECTORY, ARCHIVE_NAME, FILES)


def freeze_requirements(pip_path:str) -> None:
    try:
        with open("requirements.txt", "w") as file:
            subprocess.run([pip_path, "freeze"], stdout=file, text=True, check=True)
    except subprocess.CalledProcessError as e:
        # Error occurred
        error_message = e.stderr
        print(f"Error occurred: {error_message}")
        # Raise or handle the exception further if needed


def create_zip_archive(directory, archive_name, files) -> None:
    with zipfile.ZipFile(archive_name, 'w', zipfile.ZIP_DEFLATED) as archive:
        for file in files:
            file_path = os.path.join(directory, file)
            if os.path.isdir(file_path):
                for root, dirs, _files in os.walk(file_path):
                    for f in _files:
                        f_path = os.path.join(root, f)
                        archive_path = os.path.relpath(f_path, directory)
                        archive.write(f_path, archive_path)
            else:
                archive_path = os.path.relpath(file_path, directory)
                archive.write(file_path, archive_path)


if __name__ == "__main__":
    main()