<?php
require_once 'funciones.php';

if (hay_sesion()) {
    ir_a('inicio.php');
}

$usuario_ingresado = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $usuario_ingresado = trim($_POST['usuario'] ?? '');
    $clave = $_POST['clave'] ?? '';

    if ($usuario_ingresado === '' || $clave === '') {
        flash('danger', 'Debe ingresar su usuario y su contraseña.');
    } else {
        $sql = 'SELECT u.rut, u.nombre, u.email, u.password_hash, u.id_rol
                FROM   usuario u
                WHERE  u.rut = ? OR u.email = ?';
        $st = $pdo->prepare($sql);
        $st->execute([strtoupper($usuario_ingresado), $usuario_ingresado]);
        $fila = $st->fetch();

        if ($fila && password_verify($clave, $fila['password_hash'])) {
            unset($fila['password_hash']);
            $_SESSION['usuario'] = $fila;

            $pdo->query('CALL sp_cancelar_citas_vencidas()');

            flash('success', 'Bienvenido(a), ' . $fila['nombre'] . '.');
            ir_a('inicio.php');
        }
        flash('danger', 'Usuario o contraseña incorrectos.');
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Ingreso | SaludUSM</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="../CSS/estilos.css" rel="stylesheet">
</head>
<body class="pagina-acceso">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card tarjeta-acceso shadow">
                <div class="card-body p-4">
                    <h1 class="h3 text-center mb-1"><span class="cruz">+</span> SaludUSM</h1>
                    <p class="text-center text-muted mb-4">Sistema de gestión clínica</p>

                    <?php mostrar_flash(); ?>

                    <form method="post" action="login.php">
                        <div class="mb-3">
                            <label class="form-label" for="usuario">RUT o correo electrónico</label>
                            <input type="text" class="form-control" id="usuario" name="usuario"
                                   value="<?= h($usuario_ingresado) ?>" placeholder="12345678-9" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label" for="clave">Contraseña</label>
                            <input type="password" class="form-control" id="clave" name="clave" required>
                        </div>
                        <button type="submit" class="btn btn-salud w-100">Ingresar</button>
                    </form>

                    <hr class="my-4">
                    <p class="text-center mb-0">
                        ¿Es paciente y aún no tiene cuenta?
                        <a href="registro.php">Regístrese aquí</a>
                    </p>
                    <p class="text-center text-muted small mt-2 mb-0">
                        Los médicos y administradores son creados por el Administrador SaludUSM.
                    </p>
                </div>
            </div>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
