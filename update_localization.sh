#update Localisation

#languages
export OPT_LANGUAGES="French German pl"
#export OPT_LANGUAGES=German

#nibs
export OPT_NIBS="cocoaControl cocoaControlDiskImage cocoaControlEditPC cocoaControlNewPCAssistant cocoaControlPreferences cocoaDownload"

#prepare temp folder for languages
rm -rf "../updatedLocalizationStrings"
mkdir "../updatedLocalizationStrings"
mkdir "../updatedLocalizationStrings/English.lproj"

#create updater
cp tools/localizationStringsUpdate/* ../updatedLocalizationStrings
cd ../updatedLocalizationStrings
make
cd -

#prepare current strings from English nibs
for n in $OPT_NIBS; do \
    nibtool -L "qcontrol/Resources/English.lproj/"$n".nib" > "../updatedLocalizationStrings/English.lproj/"$n".strings"; \
    done

#inject translated strings into base strings
for d in $OPT_LANGUAGES; do \
    mkdir "../updatedLocalizationStrings/"$d".lproj/"; \
    for n in $OPT_NIBS; do \
        ../updatedLocalizationStrings/./localizationStringsUpdate "../updatedLocalizationStrings/English.lproj/"$n".strings" "qcontrol/Resources/"$d".lproj/"$n".strings" "../updatedLocalizationStrings/"$d".lproj/"$n".strings"; \
        done; \
    done