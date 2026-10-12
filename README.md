| Integrante | ROL |
|---|---|
| Cristian Bravo Osorio | 202473595-0 |
| Alex Barra Tapia | 202473526-8 |

**Repositorio:** https://github.com/CristianBvOs/T2_202473595-0_202473526-8

Ejecución

1. Copiar la carpeta `T2_202473595-0_202473526-8` dentro de `xampp\htdocs`.
2. Iniciar **Apache** y **MySQL** en el panel de XAMPP.
3. En <http://localhost/phpmyadmin> → **Importar** → `BD/salud_usm.sql` → **Continuar**.
   El script crea la base `salud_usm` desde cero y se puede reimportar las veces que sea
   necesario. Por consola: `mysql -u root -p < BD/salud_usm.sql`
4. Abrir <http://localhost/T2_202473595-0_202473526-8/PHP/login.php>

Si MySQL usa otro usuario o contraseña, editar las constantes de `PHP/conexion.php`.

Usuarios de prueba

| Rol | Usuario | Contraseña |
|---|---|---|
| Administrador | `admin@saludusm.cl` | `Admin123` |
| Médico | `camila.rojas@saludusm.cl` | `Medico123` |
| Paciente | `vicente.palma@correo.cl` | `Paciente123` |

Supuestos

1. Bloques de **30 minutos**, de **lunes a viernes entre 09:00 y 18:00** (último bloque 17:30).
   y no se consideran feriados.
2. Las citas Reservadas o Confirmadas con fecha vencida pasan a Cancelada **en cada inicio de
   sesión**, mediante `sp_cancelar_citas_vencidas()`.
3. Una cita Cancelada o No Asistió **libera su bloque**, y por lo mismo **no se reactiva**: el
   paciente debe agendar una hora nueva.
4. El médico solo deja sus citas en Confirmada, Atendida o No Asistió, y no antes de la hora de
   la cita.
5. **Al eliminar su cuenta**, el paciente borra en cascada su ficha, todas sus citas y las
   atenciones asociadas con sus diagnósticos y recetas.
6. **No se puede quitar una especialidad o un centro a un médico con citas asociadas** (de
   cualquier fecha y estado), ni eliminar un centro o un médico con citas, para no perder el
   historial.
7. Los diagnósticos salen de un catálogo compartido; el médico puede crear uno nuevo con su
   código CIE-10 y descripción. Editar uno de la atención es reemplazarlo por otro.
8. Las fechas de prueba se cuentan en días hábiles desde el lunes de la semana, asì que ninguna cae en el fin de semana
9. **Contraseña:** mínimo 8 caracteres, con al menos una mayúscula, una minúscula y un número.
