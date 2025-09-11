# Utiliser l'image officielle Flutter avec Android SDK
FROM cirrusci/flutter:stable

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers du projet dans le conteneur
COPY . .

# Télécharger les dépendances Flutter
RUN flutter pub get

# Accepter les licences Android
RUN yes | flutter doctor --android-licenses

# Builder l'APK en mode release
RUN flutter build apk --release

# Par défaut, afficher la version de Flutter
CMD ["flutter", "--version"]
