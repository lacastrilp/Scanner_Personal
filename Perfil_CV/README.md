# Scanner_CV
Proyecto para Ingeniería de Software, para el pregrado de Ingeniería de Sistemas de la Universidad EAFIT. 

Código de la clase:
- 6895 (Elizabeth Suescún)

Integrantes del equipo: 
- Alejandro Arteaga.
- Alejandra Suárez.
- Camila Vélez.
- Sara López.

> > ### **1. Clone repository from GitHub**  
> > ```sh
> > git clone git clone https://github.com/usuario/repositorio.git
> > cd repository
> > ```
> > 
> > ### **2. Install Flutter dependencies**  
> > ```sh
> > flutter pub get
> > ```
> > 
> > ### **3. Configure environment variables**  
> > 1. Make a **`.env`** file in the root of the project.  
> > 2. Agregar las siguientes líneas con las credenciales de Supabase:  
> >    ```env
> >    SUPABASE_URL=https://su-proyecto.supabase.co
> >    SUPABASE_ANON_KEY=su-clave-anonima
> >    ```
> > 3. Asegurar que el archivo `.env` esté incluido en el **`.gitignore`** para no compartir credenciales sensibles.  
> > 
> > ### **4. Importar las claves del archivo `.env` en `main.dart`**  
> > En `main.dart`, asegúrate de cargar las variables de entorno antes de acceder a Supabase:  
> > ```dart
> > import 'package:flutter_dotenv/flutter_dotenv.dart';
> > 
> > void main() async {
> >   await dotenv.load();
> >   runApp(MyApp());
> > }
> > ```
> > 
> > ### **5. Instalar Firebase CLI (para Hosting)**  
> > Si aún no tienes Firebase CLI instalado, ejecuta:  
> > ```sh
> > npm install -g firebase-tools
> > ```
> > 
> > ### **6. Iniciar sesión en Firebase**  
> > ```sh
> > firebase login
> > ```
> > 
> > ### **7. Crear un proyecto en Firebase (si no lo tienes)**  
> > 1. Ir a [[Firebase Console](https://console.firebase.google.com/)](https://console.firebase.google.com/)  
> > 2. Crear un nuevo proyecto  
> > 3. Activar **Firebase Hosting** en la configuración del proyecto  
> > 
> > ### **8. Conectar el proyecto con Firebase Hosting**  
> > ```sh
> > firebase init hosting
> > ```
> > 
> > ### **9. Ejecutar la aplicación en un emulador o dispositivo físico**  
> > ```sh
> > flutter run
> > ```


