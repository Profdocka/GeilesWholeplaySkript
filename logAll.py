import os

# Ordnerpfad
folder_path = "./characters/"

# Dateinamen im Ordner sammeln
file_names = os.listdir(folder_path)

# Textdatei zum Speichern der Dateinamen öffnen
with open("AllNames.txt", "w") as f:
    # Jeden Dateinamen in die Textdatei schreiben
    for file_name in file_names:
        name_without_extension = os.path.splitext(file_name)[0]
        f.write("\n'" + name_without_extension + "', ")
