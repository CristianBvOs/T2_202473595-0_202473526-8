<?php
require_once 'funciones.php';
requiere_rol();

$titulo = 'Mis datos';
$rut = rut_actual();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'eliminar_cuenta') {
    if (!es_paciente()) {
        flash('danger', 'Solo los pacientes pueden eliminar su propia cuenta.');
        ir_a('perfil.php');
    }

    $st = $pdo->prepare('SELECT password_hash FROM usuario WHERE rut = ?');
    $st->execute([$rut]);
    $hash = $st->fetchColumn();

    if (!$hash || !password_verify($_POST['clave_actual'] ?? '', $hash)) {
        flash('danger', 'La contraseña ingresada no es correcta. La cuenta no fue eliminada.');
        ir_a('perfil.php');
    }

    try {
        $st = $pdo->prepare('DELETE FROM usuario WHERE rut = ?');
        $st->execute([$rut]);

        $_SESSION = [];
        session_destroy();
        session_start();
        flash('success', 'Su cuenta y sus citas fueron eliminadas del sistema.');
        ir_a('login.php');
    } catch (PDOException $e) {
        flash('danger', mensaje_bd($e));
        ir_a('perfil.php');
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['accion'] ?? '') === 'guardar') {
    $nombre = trim($_POST['nombre'] ?? '');
    $email  = trim($_POST['email'] ?? '');
    $clave  = $_POST['clave'] ?? '';
    $clave2 = $_POST['clave2'] ?? '';
    $errores = [];

    if ($nombre === '') {
        $errores[] = 'El nombre es obligatorio.';
    }
    if (!validar_email($email)) {
        $errores[] = 'El correo electrónico no es válido.';
    }
    if ($clave !== '' || $clave2 !== '') {
        if (!validar_password($clave)) {
            $errores[] = 'La nueva contraseña debe tener al menos 8 caracteres, '
                       . 'una mayúscula, una minúscula y un número.';
        }
        if ($clave !== $clave2) {
            $errores[] = 'Las dos contraseñas nuevas no coinciden.';
        }
    }

    $st = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE email = ? AND rut <> ?');
    $st->execute([$email, $rut]);
    if ($st->fetchColumn() > 0) {
        $errores[] = 'Ese correo ya está registrado por otro usuario.';
    }

    if (empty($errores)) {
        try {
            $pdo->beginTransaction();

            if ($clave !== '') {
                $st = $pdo->prepare('UPDATE usuario SET nombre = ?, email = ?, password_hash = ?
                                     WHERE rut = ?');
                $st->execute([$nombre, $email, password_hash($clave, PASSWORD_DEFAULT), $rut]);
            } else {
                $st = $pdo->prepare('UPDATE usuario SET nombre = ?, email = ? WHERE rut = ?');
                $st->execute([$nombre, $email, $rut]);
            }

            if (es_paciente()) {
                $telefono = trim($_POST['telefono'] ?? '');
                $st = $pdo->prepare('UPDATE paciente
                                     SET    telefono = ?, id_comuna = ?, id_prevision = ?
                                     WHERE  rut = ?');
                $st->execute([$telefono !== '' ? $telefono : null,
                              (int)$_POST['id_comuna'], (int)$_POST['id_prevision'], $rut]);
            }

            $pdo->commit();

            $_SESSION['usuario']['nombre'] = $nombre;
            $_SESSION['usuario']['email']  = $email;
            flash('success', 'Sus datos fueron actualizados.');
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errores[] = mensaje_bd($e);
        }
    }

    foreach ($errores as $msg) {
        flash('danger', $msg);
    }
    ir_a('perfil.php');
}

$st = $pdo->prepare('SELECT u.rut, u.nombre, u.email, u.id_rol,
                            p.fecha_nacimiento, p.sexo, p.telefono, p.id_comuna, p.id_prevision
                     FROM   usuario u
                     LEFT JOIN paciente p ON p.rut = u.rut
                     WHERE  u.rut = ?');
$st->execute([$rut]);
$datos = $st->fetch();

$comunas = $pdo->query('SELECT c.id_comuna, c.nombre, r.nombre AS region
                        FROM comuna c JOIN region r ON r.id_region = c.id_region
                        ORDER BY r.nombre, c.nombre')->fetchAll();
$previsiones = $pdo->query('SELECT id_prevision, nombre FROM prevision ORDER BY nombre')->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Mis datos</h1>

<form method="post" action="perfil.php" class="card mb-4">
    <div class="card-body row g-3">
        <input type="hidden" name="accion" value="guardar">
        <div class="col-md-4">
            <label class="form-label">RUT</label>
            <input type="text" class="form-control" value="<?= h($datos['rut']) ?>" disabled>
            <div class="form-text">El RUT identifica la cuenta y no puede modificarse.</div>
        </div>
        <div class="col-md-8">
            <label class="form-label" for="nombre">Nombre completo</label>
            <input type="text" class="form-control" id="nombre" name="nombre"
                   value="<?= h($datos['nombre']) ?>" required>
        </div>
        <div class="col-md-6">
            <label class="form-label" for="email">Correo electrónico</label>
            <input type="email" class="form-control" id="email" name="email"
                   value="<?= h($datos['email']) ?>" required>
        </div>
        <div class="col-md-6">
            <label class="form-label">Perfil</label>
            <input type="text" class="form-control" value="<?= h(nombre_rol($datos['id_rol'])) ?>" disabled>
        </div>

        <?php if (es_paciente()): ?>
            <div class="col-md-4">
                <label class="form-label">Fecha de nacimiento</label>
                <input type="text" class="form-control"
                       value="<?= fecha_cl($datos['fecha_nacimiento']) ?>" disabled>
            </div>
            <div class="col-md-4">
                <label class="form-label" for="telefono">Teléfono</label>
                <input type="text" class="form-control" id="telefono" name="telefono"
                       value="<?= h($datos['telefono']) ?>">
            </div>
            <div class="col-md-4">
                <label class="form-label" for="id_prevision">Previsión</label>
                <select class="form-select" id="id_prevision" name="id_prevision">
                    <?php foreach ($previsiones as $p): ?>
                        <option value="<?= (int)$p['id_prevision'] ?>"
                            <?= $datos['id_prevision'] == $p['id_prevision'] ? 'selected' : '' ?>>
                            <?= h($p['nombre']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="id_comuna">Comuna</label>
                <select class="form-select" id="id_comuna" name="id_comuna">
                    <?php foreach ($comunas as $c): ?>
                        <option value="<?= (int)$c['id_comuna'] ?>"
                            <?= $datos['id_comuna'] == $c['id_comuna'] ? 'selected' : '' ?>>
                            <?= h($c['nombre']) ?> (<?= h($c['region']) ?>)</option>
                    <?php endforeach; ?>
                </select>
            </div>
        <?php endif; ?>

        <div class="col-md-6">
            <label class="form-label" for="clave">Nueva contraseña (opcional)</label>
            <input type="password" class="form-control" id="clave" name="clave">
            <div class="form-text">Mínimo 8 caracteres, una mayúscula, una minúscula y un número.</div>
        </div>
        <div class="col-md-6">
            <label class="form-label" for="clave2">Repetir nueva contraseña</label>
            <input type="password" class="form-control" id="clave2" name="clave2">
        </div>

        <div class="col-12 text-end">
            <button class="btn btn-salud" type="submit">Guardar cambios</button>
        </div>
    </div>
</form>

<?php if (es_paciente()): ?>
    <div class="card border-danger">
        <div class="card-body">
            <h2 class="h6 text-danger">Eliminar mi cuenta</h2>
            <p class="mb-3 small text-muted">
                Al eliminar su cuenta se borran también todas sus citas y las atenciones
                asociadas a ellas. Esta acción no se puede deshacer.
            </p>
            <form method="post" action="perfil.php"
                  onsubmit="return confirm('Se eliminará su cuenta y todas sus citas. ¿Está seguro?');">
                <input type="hidden" name="accion" value="eliminar_cuenta">
                <div class="row g-2">
                    <div class="col-md-4">
                        <input type="password" class="form-control" name="clave_actual"
                               placeholder="Confirme su contraseña" required>
                    </div>
                    <div class="col-md-3">
                        <button class="btn btn-outline-danger w-100" type="submit">Eliminar cuenta</button>
                    </div>
                </div>
            </form>
        </div>
    </div>
<?php endif; ?>

<?php require 'pie.php'; ?>
