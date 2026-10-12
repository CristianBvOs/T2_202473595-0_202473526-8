<?php
require_once 'funciones.php';

if (hay_sesion()) {
    ir_a('inicio.php');
}

$comunas = $pdo->query('SELECT c.id_comuna, c.nombre, r.nombre AS region
                        FROM comuna c JOIN region r ON r.id_region = c.id_region
                        ORDER BY r.nombre, c.nombre')->fetchAll();
$previsiones = $pdo->query('SELECT id_prevision, nombre FROM prevision ORDER BY nombre')->fetchAll();

$datos = ['rut' => '', 'nombre' => '', 'email' => '', 'fecha_nacimiento' => '',
          'sexo' => '', 'telefono' => '', 'id_comuna' => '', 'id_prevision' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    foreach ($datos as $campo => $_) {
        $datos[$campo] = trim($_POST[$campo] ?? '');
    }
    $datos['rut'] = strtoupper($datos['rut']);
    $clave   = $_POST['clave'] ?? '';
    $clave2  = $_POST['clave2'] ?? '';
    $errores = [];

    if (!validar_rut($datos['rut'])) {
        $errores[] = 'El RUT debe tener el formato XXXXXXXX-X y un dígito verificador válido.';
    }
    if ($datos['nombre'] === '') {
        $errores[] = 'El nombre completo es obligatorio.';
    }
    if (!validar_email($datos['email'])) {
        $errores[] = 'El correo electrónico no es válido.';
    }
    if ($datos['fecha_nacimiento'] === '' || $datos['fecha_nacimiento'] > date('Y-m-d')) {
        $errores[] = 'La fecha de nacimiento es obligatoria y no puede ser futura.';
    }
    if (!in_array($datos['sexo'], ['M', 'F', 'O'], true)) {
        $errores[] = 'Debe seleccionar el sexo.';
    }
    if ($datos['id_comuna'] === '' || $datos['id_prevision'] === '') {
        $errores[] = 'Debe seleccionar comuna y previsión.';
    }
    if (!validar_password($clave)) {
        $errores[] = 'La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.';
    }
    if ($clave !== $clave2) {
        $errores[] = 'Las dos contraseñas no coinciden.';
    }

    if (empty($errores)) {
        $st = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE rut = ?');
        $st->execute([$datos['rut']]);
        if ($st->fetchColumn() > 0) {
            $errores[] = 'Ya existe un usuario registrado con ese RUT.';
        }
        $st = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE email = ?');
        $st->execute([$datos['email']]);
        if ($st->fetchColumn() > 0) {
            $errores[] = 'Ya existe un usuario registrado con ese correo.';
        }
    }

    if (empty($errores)) {
        try {
            $pdo->beginTransaction();
            $st = $pdo->prepare('INSERT INTO usuario (rut, nombre, email, password_hash, id_rol)
                                 VALUES (?, ?, ?, ?, ?)');
            $st->execute([$datos['rut'], $datos['nombre'], $datos['email'],
                          password_hash($clave, PASSWORD_DEFAULT), ROL_PACIENTE]);

            $st = $pdo->prepare('INSERT INTO paciente (rut, fecha_nacimiento, sexo, telefono,
                                                       id_comuna, id_prevision)
                                 VALUES (?, ?, ?, ?, ?, ?)');
            $st->execute([$datos['rut'], $datos['fecha_nacimiento'], $datos['sexo'],
                          $datos['telefono'] !== '' ? $datos['telefono'] : null,
                          $datos['id_comuna'], $datos['id_prevision']]);
            $pdo->commit();

            flash('success', 'Registro exitoso. Ya puede iniciar sesión con su RUT o correo.');
            ir_a('login.php');
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errores[] = mensaje_bd($e);
        }
    }

    foreach ($errores as $msg) {
        flash('danger', $msg);
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Registro de paciente | SaludUSM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="../CSS/estilos.css" rel="stylesheet">
</head>
<body class="pagina-acceso">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-lg-7">
            <div class="card tarjeta-acceso shadow">
                <div class="card-body p-4">
                    <h1 class="h4 mb-3">Registro de paciente</h1>
                    <?php mostrar_flash(); ?>
                    <form method="post" action="registro.php" class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label" for="rut">RUT</label>
                            <input type="text" class="form-control" id="rut" name="rut"
                                   placeholder="12345678-9" value="<?= h($datos['rut']) ?>" required>
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
                        <div class="col-md-3">
                            <label class="form-label" for="fecha_nacimiento">Fecha de nacimiento</label>
                            <input type="date" class="form-control" id="fecha_nacimiento"
                                   name="fecha_nacimiento" value="<?= h($datos['fecha_nacimiento']) ?>" required>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label" for="sexo">Sexo</label>
                            <select class="form-select" id="sexo" name="sexo" required>
                                <option value="">Seleccione...</option>
                                <option value="M" <?= $datos['sexo'] === 'M' ? 'selected' : '' ?>>Masculino</option>
                                <option value="F" <?= $datos['sexo'] === 'F' ? 'selected' : '' ?>>Femenino</option>
                                <option value="O" <?= $datos['sexo'] === 'O' ? 'selected' : '' ?>>Otro</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="telefono">Teléfono (opcional)</label>
                            <input type="text" class="form-control" id="telefono" name="telefono"
                                   value="<?= h($datos['telefono']) ?>">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="id_comuna">Comuna</label>
                            <select class="form-select" id="id_comuna" name="id_comuna" required>
                                <option value="">Seleccione...</option>
                                <?php foreach ($comunas as $c): ?>
                                    <option value="<?= (int)$c['id_comuna'] ?>"
                                        <?= $datos['id_comuna'] == $c['id_comuna'] ? 'selected' : '' ?>>
                                        <?= h($c['nombre']) ?> (<?= h($c['region']) ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="id_prevision">Previsión</label>
                            <select class="form-select" id="id_prevision" name="id_prevision" required>
                                <option value="">Seleccione...</option>
                                <?php foreach ($previsiones as $p): ?>
                                    <option value="<?= (int)$p['id_prevision'] ?>"
                                        <?= $datos['id_prevision'] == $p['id_prevision'] ? 'selected' : '' ?>>
                                        <?= h($p['nombre']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="clave">Contraseña</label>
                            <input type="password" class="form-control" id="clave" name="clave" required>
                            <div class="form-text">
                                Mínimo 8 caracteres, con al menos una mayúscula, una minúscula y un número.
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="clave2">Repetir contraseña</label>
                            <input type="password" class="form-control" id="clave2" name="clave2" required>
                        </div>
                        <div class="col-12 d-flex justify-content-between">
                            <a href="login.php" class="btn btn-outline-secondary">Volver al ingreso</a>
                            <button type="submit" class="btn btn-salud">Crear cuenta</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
