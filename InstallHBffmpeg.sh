#!/bin/bash
yellow=$(tput setf 6) ; red=$(tput setf 4) ; green=$(tput setf 2) ; reset=$(tput sgr0)
cmdkey=0 ; ME=`basename $0` cd~ ; clear



function Zagolovok {
echo -en "${yellow} \n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                $ZI HB-Camera-ffmpeg и его зависимостей.               ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n ${reset}"
}
function GoToMenu {
  GoToMenuInfo="Чтобы продолжить, введите"
while :
	do
	clear
	ZI=Установка && Zagolovok 
	echo -en "\n"
	echo "     ┌─ Выберите действие: ──────────────────────────────────────────────┐"
	echo "     │                                                                   │"
	echo -en "\n" 
	echo "           1 - Установка HB-Camera-ffmpeg на чистой системе $InstallInfo"
	echo -en "\n"
	echo "           2 - Установка HB-Camera-ffmpeg с полным удалением старой версии $ReinstallInfo"
	echo -en "\n"
	echo "           3 - Полное удаление HB-Camera-ffmpeg с очисткой системы $UninstallInfo"
	echo -en "\n"
	echo "           0 - Завершение работы с самоудалением скрипта"
	echo -en "\n"
	echo "     │                                                                   │"
	echo "     └────────────────────────────────────────────── H - Вызов справки ──┘"
	echo -en "\n"
	echo -e "\a"
	echo "           $GoToMenuInfo номер пункта и нажмите на Enter"
	echo -e "\a"
	read item
	printf "\n"
	case "$item" in

		0) 	RremovalItself ;;

		1) 	ReinstallInfo="" ; InstallScript ;;

		2) 	cmdkey=1 ; UninstallScript ; cmdkey=0 ; InstallScript ;;

		3) 	ReinstallInfo="" ; UninstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	clear && GoToMenuInfo="Попробуйте еще раз ввести" ;;

	esac
done
}




function СheckingInstalledPackage() {
InstalledPackageKey=0 ; echo -en "\n" ; echo "  # # Проверка на ранее установленную версию..."
if dpkg -l homebridge &>/dev/null; then
	echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge как системный пакет..."
	InstallInfo="${green}[уже установлен]${reset}"
	InstalledPackageKey=1
elif dpkg -l nodejs &>/dev/null; then
	if npm list -g | grep -q homebridge; then
		echo -en "\n" ; echo "     - В вашей системе уже установлен HomeBridge из NPM..."
		InstallInfo="${green}[уже установлен]${reset}"
		InstalledPackageKey=1
	else
		echo -en "\n" ; echo "     - В системе уже установлен пакет Node.js ${green}$(node -v | tr -d ' ')${reset}, но HomeBridge не установлен..."
		InstallInfo="${red}[установлен NodeJS]${reset}"
		InstalledPackageKey=1
	fi
fi

if [ $InstalledPackageKey -eq 1 ]; then
	if [ $cmdkey -eq 1 ]; then
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы завершить работу скрипта...${reset}"
		exit 0
	else
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
		GoToMenu
	fi
fi
}




function InstallScript() {
clear
ZI="Установка" && Zagolovok
###СheckingInstalledPackage


echo -en "\n" ; echo "  # # Обновление кеша данных и индексов репозиторий..."
sudo rm -Rf /var/lib/apt/lists/*
sudo apt update -y > /dev/null 2>&1
sudo apt upgrade -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Установка необходимых зависимостей..."
sudo apt install -y git pkg-config autoconf automake libtool libx264-dev > /dev/null 2>&1


#echo -en "\n" ; echo "  # # Устранение ранее известных проблем..."

echo -en "\n" ; echo "  # # Установка пакета AAC..."
git clone https://github.com/mstorsjo/fdk-aac.git > /dev/null 2>&1
cd ~/fdk-aac
./autogen.sh > /dev/null 2>&1
./configure --prefix=/usr/local --enable-shared --enable-static > /dev/null 2>&1
make -j4 > /dev/null 2>&1
sudo make install > /dev/null 2>&1
sudo ldconfig > /dev/null 2>&1
cd ~



echo -en "\n" ; echo "  # # Установка пакета FFMPEG..."
git clone https://github.com/FFmpeg/FFmpeg.git > /dev/null 2>&1
cd ~/FFmpeg
./configure --prefix=/usr/local --arch=armel --target-os=linux --enable-omx-rpi --enable-nonfree --enable-gpl --enable-libfdk-aac --enable-mmal --enable-libx264 --enable-decoder=h264 --enable-network --enable-protocol=tcp --enable-demuxer=rtsp
make -j4
sudo make install
cd ~

echo -en "\n" ; echo "  # # Установка плагина для homebridge..."
sudo hb-service add homebridge-camera-ffmpeg@latest > /dev/null 2>&1

echo -en "\n" ; echo "  # # Очистка системы..."
#Удаление директории fdk-aac и FFmpeg
sudo rm -rf ~/fdk-aac > /dev/null 2>&1
sudo rm -rf ~/FFmpeg > /dev/null 2>&1

echo -en "\n" ; echo "  # # Перезапуск homebridge..."
sudo hb-service restart > /dev/null 2>&1


echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║           ${green}Установки HB-Camera-ffmpeg и его зависимостей завершена${reset}           ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

InstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function UninstallScript() {
clear ; CheckBackUp=0 ; BackupRecovery=0
ZI=" Удаление" && Zagolovok

echo -en "\n" ; echo "  # # Остановка и завершение процесса Homebridge..."
sudo hb-service stop > /dev/null 2>&1
sudo systemctl stop homebridge > /dev/null 2>&1
sudo service homebridge stop > /dev/null 2>&1
sudo pm2 stop all > /dev/null 2>&1
sudo killall -w -s 9 -u homebridge > /dev/null 2>&1

echo -en "\n" ; echo "  # # Деинсталляция плагина для homebridge..."
sudo hb-service remove homebridge-camera-ffmpeg

echo -en "\n" ; echo "  # # Удаление пакета AAC..."
####sudo > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление пакета FFMPEG..."
####sudo > /dev/null 2>&1

echo -en "\n" ; echo "  # # Перезапуск homebridge..."
sudo hb-service restart

echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "   ${green}Удаление HB-Camera-ffmpeg завершена${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UninstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function RremovalItself() {

#Удаление директории ~/fdk-aac
sudo rm -rf ~/fdk-aac
#Удаление директории ~/FFmpeg
sudo rm -rf ~/FFmpeg

echo -en "\n" ; echo "                   Самоудаление папки со скриптом установки...  " ; cd ~
sudo rm -rf ~/HB-Camera-ffmpeg-Install-Script

if [ $? -eq 0 ]; then
	echo "                ${green}[Успешно удалено]${reset} - ${red}Завершение работы скрипта...${reset}" ; echo -en "\n"
else
	echo "            ${red}[Удаление не удалось] - Завершение работы скрипта...${reset}" ; echo -en "\n"
fi
sleep 1
exit 0
}



function print_help() {
	echo -en "\n"
	echo "  ${yellow}Справка по работе скрипта $ME из командной строки${reset}"
	echo -en "\n"
	echo "    Использование: $ME [-i] [-u] [-r] [-d] [-h] "
	echo -en "\n"
	echo "        Параметры:"
	echo "            -i        Установка Homebridge на чистой системе."
	echo "            -u        Полное удаление Homebridge с очисткой системы."
	echo "            -r        Установка Homebridge с полным удалением старой версии."
	echo "            -d        Самоудаление папки со скриптом установки."
	echo -en "\n"
	echo "            -h        Вызов справки."
	echo -en "\n"
exit 0
}





# Если скрипт запущен без аргументов, открываем справку.
if [ $# = 0 ]; then
	GoToMenu
fi

while getopts ":uUiIrRhHdD" Option
	do

	cmdkey=1
 
	case $Option in

		I|i) 	InstallScript ;;

		U|u) 	UninstallScript ;;

		R|r) 	UninstallScript ; InstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	echo -en "\n" ; echo -en "\n"
			echo "${red}           Неправильный параметр!${reset}"
			print_help ; exit 1 ;;
	esac
done

shift $(($OPTIND - 1))

exit 0
