## 1. Integrantes

| Nombre | ROL |
| Cristian Bravo Osorio | 202473595-0 |
| Alex Barra Tapia      | 202473526-8 |

**Repositorio GitHub:** https://github.com/CristianBvOs/T2_202473595-0_202473526-8

-------------

## 2. Instrucciones de ejecución

Requisitos: **XAMPP 8.x** (PHP 8.0 o superior y MySQL/MariaDB).

1. Copiar la carpeta completa `T2_202473595-0_202473526-8` dentro de `xampp\htdocs`.
2. Abrir el panel de XAMPP e iniciar **Apache** y **MySQL**.
3. Entrar a <http://localhost/phpmyadmin>, ir a la pestaña **Importar**, seleccionar el archivo
`BD/salud_usm.sql` y presionar **Continuar**. El script crea la base de datos `salud_usm`
desde cero (incluye `DROP DATABASE IF EXISTS`, por lo que se puede volver a importar las
veces que sea necesario).
- Alternativa por consola: `mysql -u root -p < BD/salud_usm.sql`
4. Abrir <http://localhost/T2_202473595-0_202473526-8/PHP/login.php> e ingresar con alguno de los usuarios de
prueba de la sección 4.

Si el servidor MySQL usa un usuario o una contraseña distintos de los de XAMPP por defecto
(`root` sin contraseña), hay que editar las cuatro constantes del archivo `PHP/conexion.php`.

------------

## 3. Usuarios de prueba


### Administrador 'admin@saludusm.cl' - contraseña 'Admin123'

### Médicos  'martina.navarro@saludusm.cl' — contraseña 'Medico123'
Los 15 médicos del sistema usan la misma contraseña.

### Pacientes 'vicente.palma@correo.cl' — contraseña 'Paciente123'
Los 40 pacientes del sistema usan la misma contraseña.

---------------

## 4. Supuestos

- **Duración de cada bloque: 30 minutos.**
- **Horario de atención: lunes a viernes, de 09:00 a 18:00.**
- Al agendar o reprogramar, el sistema ofrece solo los bloques que el médico tiene libres ese
  día. Si la fecha elegida es hoy, además se descartan los bloques cuya hora ya pasó.
- El paciente puede eliminar su cuenta desde *Mis datos*, confirmando su contraseña.
- La eliminación es **física y en cascada**: se borra el usuario, su ficha de paciente,
  **todas sus citas** (pasadas y futuras) y las **atenciones** asociadas a esas citas, junto
  con los diagnósticos y las recetas de dichas atenciones.
- Se puede iniciar sesión con el **RUT** o con el **correo electrónico**.
- **Requisitos de contraseña:** mínimo 8 caracteres, al menos una letra mayúscula, al menos una
  letra minúscula y al menos un número.
- El sexo del paciente se registra como M (masculino), F (femenino) u O (otro).

