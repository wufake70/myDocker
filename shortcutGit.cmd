@echo off
chcp 65001 >nul
color 2
git add .
git commit . -m"%date% %time%"
git push origin main
set /p input=Go to Git[Y/N]:

if "%input%"=="y" (goto GoToGit)
if "%input%"=="Y" (goto GoToGit)

color 7
pause > nul
exit

:GoToGit
start https://github.com/wufake70/myDocker
color 7
pause > nul
exit