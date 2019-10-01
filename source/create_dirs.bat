@echo off
ECHO Creating Live Editor folder in Documents\FIFA 20
SET fifa_docs = %HOMEDRIVE%\Users\%USERNAME%\Documents\FIFA 20\
SET le_path=%fifa_docs%Live Editor\
mkdir "%le_path%data\"
ECHO A | xcopy cache "%le_path%cache" /E /i