<?php
require_once 'funciones.php';
requiere_rol([ROL_ADMIN]);

$titulo = 'Médicos';

$rut_editar = trim($_GET['editar'] ?? $_POST['rut_medico'] ?? '');
$es_edicion = $rut_editar !== '';

$datos = ['rut' => '', 'nombre' => '', 'email' => '', 'fecha_ingreso' => date('Y-m-d')];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';

    try {

        if ($accion === 'guardar') {
            $datos['nombre']        = trim($_POST['nombre'] ?? '');
            $datos['email']         = trim($_POST['email'] ?? '');
            $datos['fecha_ingreso'] = trim($_POST['fecha_ingreso'] ?? date('Y-m-d'));
            $clave   = $_POST['clave'] ?? '';
            $errores = [];

            if ($es_edicion) {
                $datos['rut'] = $rut_editar;
                if ($clave !== '' && !validar_password($clave)) {
                    $errores[] = 'La nueva contraseña debe tener al menos 8 caracteres, '
                               . 'una mayúscula, una minúscula y un número.';
                }
            } else {
                $datos['rut'] = strtoupper(trim($_POST['rut'] ?? ''));
                $esp_elegidas = array_map('intval', $_POST['especialidades'] ?? []);
                $cen_elegidos = array_map('intval', $_POST['centros'] ?? []);

                if (!validar_rut($datos['rut'])) {
                    $errores[] = 'El RUT debe tener el formato XXXXXXXX-X y un dígito verificador válido.';
                }
                if (!validar_password($clave)) {
                    $errores[] = 'La contraseña inicial debe tener al menos 8 caracteres, '
                               . 'una mayúscula, una minúscula y un número.';
                }
                if (count($esp_elegidas) < 1 || count($esp_elegidas) > 3) {
                    $errores[] = 'Debe asignar entre 1 y 3 especialidades.';
                }
                if (count($cen_elegidos) < 1) {
                    $errores[] = 'Debe asignar al menos un centro de atención.';
                }

                $st = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE rut = ?');
                $st->execute([$datos['rut']]);
                if ($st->fetchColumn() > 0) {
                    $errores[] = 'Ya existe un usuario con ese RUT.';
                }
            }

            if ($datos['nombre'] === '')         { $errores[] = 'El nombre es obligatorio.'; }
            if (!validar_email($datos['email'])) { $errores[] = 'El correo electrónico no es válido.'; }

            $st = $pdo->prepare('SELECT COUNT(*) FROM usuario WHERE email = ? AND rut <> ?');
            $st->execute([$datos['email'], $datos['rut']]);
            if ($st->fetchColumn() > 0) {
                $errores[] = 'Ese correo ya está registrado por otro usuario.';
            }

            if (empty($errores)) {

                $pdo->beginTransaction();

                if ($es_edicion) {
                    if ($clave !== '') {
                        $st = $pdo->prepare('UPDATE usuario SET nombre = ?, email = ?, password_hash = ?
                                             WHERE rut = ?');
                        $st->execute([$datos['nombre'], $datos['email'],
                                      password_hash($clave, PASSWORD_DEFAULT), $datos['rut']]);
                    } else {
                        $st = $pdo->prepare('UPDATE usuario SET nombre = ?, email = ? WHERE rut = ?');
                        $st->execute([$datos['nombre'], $datos['email'], $datos['rut']]);
                    }
                    $st = $pdo->prepare('UPDATE medico SET fecha_ingreso = ? WHERE rut = ?');
                    $st->execute([$datos['fecha_ingreso'], $datos['rut']]);
                    $pdo->commit();
                    flash('success', 'Datos del médico actualizados.');
                    ir_a('admin_medicos.php?editar=' . urlencode($datos['rut']));
                } else {
                    $st = $pdo->prepare('INSERT INTO usuario (rut, nombre, email, password_hash, id_rol)
                                         VALUES (?, ?, ?, ?, ?)');
                    $st->execute([$datos['rut'], $datos['nombre'], $datos['email'],
                                  password_hash($clave, PASSWORD_DEFAULT), ROL_MEDICO]);

                    $st = $pdo->prepare('INSERT INTO medico (rut, fecha_ingreso) VALUES (?, ?)');
                    $st->execute([$datos['rut'], $datos['fecha_ingreso']]);

                    $st = $pdo->prepare('INSERT INTO medico_especialidad (rut_medico, id_especialidad)
                                         VALUES (?, ?)');
                    foreach ($esp_elegidas as $id) {
                        $st->execute([$datos['rut'], $id]);
                    }

                    $st = $pdo->prepare('INSERT INTO medico_centro (rut_medico, id_centro) VALUES (?, ?)');
                    foreach ($cen_elegidos as $id) {
                        $st->execute([$datos['rut'], $id]);
                    }

                    $pdo->commit();
                    flash('success', 'Médico creado correctamente.');
                    ir_a('admin_medicos.php');
                }
            }

            foreach ($errores as $m) {
                flash('danger', $m);
            }

        } elseif ($accion === 'eliminar') {
            $st = $pdo->prepare('SELECT COUNT(*) FROM cita WHERE rut_medico = ?');
            $st->execute([$rut_editar]);
            if ($st->fetchColumn() > 0) {
                flash('danger', 'No se puede eliminar al médico: tiene citas registradas en el sistema.');
            } else {
                $st = $pdo->prepare('DELETE FROM usuario WHERE rut = ?');
                $st->execute([$rut_editar]);
                flash('success', 'Médico eliminado del sistema.');
            }
            ir_a('admin_medicos.php');

        } elseif ($accion === 'agregar_especialidad') {
            $st = $pdo->prepare('INSERT INTO medico_especialidad (rut_medico, id_especialidad)
                                 VALUES (?, ?)');
            $st->execute([$rut_editar, (int)$_POST['id_especialidad']]);
            flash('success', 'Especialidad agregada al médico.');
            ir_a('admin_medicos.php?editar=' . urlencode($rut_editar));

        } elseif ($accion === 'quitar_especialidad') {
            $id = (int)$_POST['id_especialidad'];

            $st = $pdo->prepare('SELECT COUNT(*) FROM medico_especialidad WHERE rut_medico = ?');
            $st->execute([$rut_editar]);
            $total = (int)$st->fetchColumn();

            $st = $pdo->prepare('SELECT COUNT(*) FROM cita
                                 WHERE rut_medico = ? AND id_especialidad = ? AND fecha >= CURDATE()');
            $st->execute([$rut_editar, $id]);
            $futuras = (int)$st->fetchColumn();

            if ($total <= 1) {
                flash('warning', 'El médico debe conservar al menos una especialidad.');
            } elseif ($futuras > 0) {
                flash('warning', 'No se puede quitar la especialidad: el médico tiene citas futuras '
                               . 'agendadas en ella. Primero debe reprogramarlas o cancelarlas.');
            } else {
                $st = $pdo->prepare('DELETE FROM medico_especialidad
                                     WHERE rut_medico = ? AND id_especialidad = ?');
                $st->execute([$rut_editar, $id]);
                flash('success', 'Especialidad quitada del médico.');
            }
            ir_a('admin_medicos.php?editar=' . urlencode($rut_editar));

        } elseif ($accion === 'agregar_centro') {
            $st = $pdo->prepare('INSERT INTO medico_centro (rut_medico, id_centro) VALUES (?, ?)');
            $st->execute([$rut_editar, (int)$_POST['id_centro']]);
            flash('success', 'Centro agregado al médico.');
            ir_a('admin_medicos.php?editar=' . urlencode($rut_editar));

        } elseif ($accion === 'quitar_centro') {
            $id = (int)$_POST['id_centro'];

            $st = $pdo->prepare('SELECT COUNT(*) FROM medico_centro WHERE rut_medico = ?');
            $st->execute([$rut_editar]);
            $total = (int)$st->fetchColumn();

            $st = $pdo->prepare('SELECT COUNT(*) FROM cita
                                 WHERE rut_medico = ? AND id_centro = ? AND fecha >= CURDATE()');
            $st->execute([$rut_editar, $id]);
            $futuras = (int)$st->fetchColumn();

            if ($total <= 1) {
                flash('warning', 'El médico debe atender al menos en un centro.');
            } elseif ($futuras > 0) {
                flash('warning', 'No se puede quitar el centro: el médico tiene citas futuras '
                               . 'agendadas allí. Primero debe reprogramarlas o cancelarlas.');
            } else {
                $st = $pdo->prepare('DELETE FROM medico_centro WHERE rut_medico = ? AND id_centro = ?');
                $st->execute([$rut_editar, $id]);
                flash('success', 'Centro quitado del médico.');
            }
            ir_a('admin_medicos.php?editar=' . urlencode($rut_editar));
        }
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        flash('danger', mensaje_bd($e));
    }
}

$esp_asignadas = [];
$cen_asignados = [];

if ($es_edicion) {
    $st = $pdo->prepare('SELECT u.rut, u.nombre, u.email, m.fecha_ingreso
                         FROM   medico m JOIN usuario u ON u.rut = m.rut
                         WHERE  m.rut = ?');
    $st->execute([$rut_editar]);
    $encontrado = $st->fetch();
    if (!$encontrado) {
        flash('danger', 'El médico indicado no existe.');
        ir_a('admin_medicos.php');
    }
    $datos = $encontrado;

    $st = $pdo->prepare('SELECT e.id_especialidad, e.nombre
                         FROM   medico_especialidad me
                         JOIN   especialidad e ON e.id_especialidad = me.id_especialidad
                         WHERE  me.rut_medico = ? ORDER BY e.nombre');
    $st->execute([$rut_editar]);
    $esp_asignadas = $st->fetchAll();

    $st = $pdo->prepare('SELECT c.id_centro, c.nombre, co.nombre AS comuna
                         FROM   medico_centro mc
                         JOIN   centro_medico c ON c.id_centro = mc.id_centro
                         JOIN   comuna co ON co.id_comuna = c.id_comuna
                         WHERE  mc.rut_medico = ? ORDER BY c.nombre');
    $st->execute([$rut_editar]);
    $cen_asignados = $st->fetchAll();
}

$especialidades = $pdo->query('SELECT id_especialidad, nombre FROM especialidad ORDER BY nombre')->fetchAll();
$centros = $pdo->query('SELECT id_centro, nombre FROM centro_medico ORDER BY nombre')->fetchAll();

$medicos = $pdo->query("SELECT u.rut, u.nombre, u.email,
                               (SELECT GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ')
                                  FROM medico_especialidad me
                                  JOIN especialidad e ON e.id_especialidad = me.id_especialidad
                                 WHERE me.rut_medico = m.rut) AS especialidades,
                               (SELECT GROUP_CONCAT(c.nombre ORDER BY c.nombre SEPARATOR ', ')
                                  FROM medico_centro mc
                                  JOIN centro_medico c ON c.id_centro = mc.id_centro
                                 WHERE mc.rut_medico = m.rut) AS centros,
                               (SELECT COUNT(*) FROM cita ci
                                 WHERE ci.rut_medico = m.rut AND ci.fecha >= CURDATE()) AS citas_futuras
                        FROM   medico  m
                        JOIN   usuario u ON u.rut = m.rut
                        ORDER BY u.nombre")->fetchAll();

function ya_asignado($lista, $campo, $id)
{
    foreach ($lista as $fila) {
        if ((int)$fila[$campo] === (int)$id) {
            return true;
        }
    }
    return false;
}

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Médicos</h1>
<div class="card mb-4">
    <div class="card-header">
        <?= $es_edicion ? 'Editar médico: ' . h($datos['nombre']) : 'Nuevo médico' ?>
    </div>
    <div class="card-body">
        <form method="post" action="admin_medicos.php" class="row g-3">
            <input type="hidden" name="accion" value="guardar">
            <input type="hidden" name="rut_medico" value="<?= h($es_edicion ? $rut_editar : '') ?>">

            <div class="col-md-3">
                <label class="form-label" for="rut">RUT</label>
                <input type="text" class="form-control" id="rut" name="rut" placeholder="12345678-9"
                       value="<?= h($datos['rut']) ?>" <?= $es_edicion ? 'disabled' : 'required' ?>>
            </div>
            <div class="col-md-5">
                <label class="form-label" for="nombre">Nombre completo</label>
                <input type="text" class="form-control" id="nombre" name="nombre"
                       value="<?= h($datos['nombre']) ?>" required>
            </div>
            <div class="col-md-4">
                <label class="form-label" for="email">Correo electrónico</label>
                <input type="email" class="form-control" id="email" name="email"
                       value="<?= h($datos['email']) ?>" required>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="fecha_ingreso">Fecha de ingreso</label>
                <input type="date" class="form-control" id="fecha_ingreso" name="fecha_ingreso"
                       value="<?= h($datos['fecha_ingreso']) ?>" required>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="clave">
                    <?= $es_edicion ? 'Nueva contraseña (opcional)' : 'Contraseña inicial' ?>
                </label>
                <input type="password" class="form-control" id="clave" name="clave"
                       <?= $es_edicion ? '' : 'required' ?>>
            </div>

            <?php if (!$es_edicion): ?>
                <div class="col-md-3">
                    <label class="form-label">Especialidades (entre 1 y 3)</label>
                    <?php foreach ($especialidades as $e): ?>
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="especialidades[]"
                                   value="<?= (int)$e['id_especialidad'] ?>"
                                   id="esp<?= (int)$e['id_especialidad'] ?>">
                            <label class="form-check-label" for="esp<?= (int)$e['id_especialidad'] ?>">
                                <?= h($e['nombre']) ?>
                            </label>
                        </div>
                    <?php endforeach; ?>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Centros donde atiende (al menos 1)</label>
                    <?php foreach ($centros as $c): ?>
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="centros[]"
                                   value="<?= (int)$c['id_centro'] ?>" id="cen<?= (int)$c['id_centro'] ?>">
                            <label class="form-check-label" for="cen<?= (int)$c['id_centro'] ?>">
                                <?= h($c['nombre']) ?>
                            </label>
                        </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>

            <div class="col-12 d-flex gap-2">
                <button class="btn btn-salud" type="submit">Guardar</button>
                <?php if ($es_edicion): ?>
                    <a class="btn btn-outline-secondary" href="admin_medicos.php">Cancelar</a>
                <?php endif; ?>
            </div>
        </form>
    </div>
</div>

<?php if ($es_edicion): ?>

<div class="row g-4 mb-4">
    <div class="col-lg-6">
        <div class="card h-100">
            <div class="card-header">Especialidades (<?= count($esp_asignadas) ?> de 3)</div>
            <ul class="list-group list-group-flush">
                <?php foreach ($esp_asignadas as $e): ?>
                    <li class="list-group-item d-flex justify-content-between align-items-center">
                        <?= h($e['nombre']) ?>
                        <form method="post" action="admin_medicos.php">
                            <input type="hidden" name="rut_medico" value="<?= h($rut_editar) ?>">
                            <input type="hidden" name="accion" value="quitar_especialidad">
                            <input type="hidden" name="id_especialidad" value="<?= (int)$e['id_especialidad'] ?>">
                            <button class="btn btn-sm btn-outline-danger" type="submit">Quitar</button>
                        </form>
                    </li>
                <?php endforeach; ?>
            </ul>
            <div class="card-body">
                <?php if (count($esp_asignadas) >= 3): ?>
                    <p class="text-muted small mb-0">
                        El médico ya tiene el máximo de 3 especialidades permitidas.
                    </p>
                <?php else: ?>
                    <form method="post" action="admin_medicos.php" class="row g-2">
                        <input type="hidden" name="rut_medico" value="<?= h($rut_editar) ?>">
                        <input type="hidden" name="accion" value="agregar_especialidad">
                        <div class="col-8">
                            <select class="form-select" name="id_especialidad" required>
                                <option value="">Agregar especialidad...</option>
                                <?php foreach ($especialidades as $e): ?>
                                    <?php if (ya_asignado($esp_asignadas, 'id_especialidad', $e['id_especialidad'])) continue; ?>
                                    <option value="<?= (int)$e['id_especialidad'] ?>"><?= h($e['nombre']) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-4 d-grid">
                            <button class="btn btn-salud" type="submit">Agregar</button>
                        </div>
                    </form>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <div class="col-lg-6">
        <div class="card h-100">
            <div class="card-header">Centros donde atiende (<?= count($cen_asignados) ?>)</div>
            <ul class="list-group list-group-flush">
                <?php foreach ($cen_asignados as $c): ?>
                    <li class="list-group-item d-flex justify-content-between align-items-center">
                        <span><?= h($c['nombre']) ?><br>
                            <span class="text-muted small"><?= h($c['comuna']) ?></span></span>
                        <form method="post" action="admin_medicos.php">
                            <input type="hidden" name="rut_medico" value="<?= h($rut_editar) ?>">
                            <input type="hidden" name="accion" value="quitar_centro">
                            <input type="hidden" name="id_centro" value="<?= (int)$c['id_centro'] ?>">
                            <button class="btn btn-sm btn-outline-danger" type="submit">Quitar</button>
                        </form>
                    </li>
                <?php endforeach; ?>
            </ul>
            <div class="card-body">
                <form method="post" action="admin_medicos.php" class="row g-2">
                    <input type="hidden" name="rut_medico" value="<?= h($rut_editar) ?>">
                    <input type="hidden" name="accion" value="agregar_centro">
                    <div class="col-8">
                        <select class="form-select" name="id_centro" required>
                            <option value="">Agregar centro...</option>
                            <?php foreach ($centros as $c): ?>
                                <?php if (ya_asignado($cen_asignados, 'id_centro', $c['id_centro'])) continue; ?>
                                <option value="<?= (int)$c['id_centro'] ?>"><?= h($c['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="col-4 d-grid">
                        <button class="btn btn-salud" type="submit">Agregar</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>

<div class="table-responsive">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Médico</th>
                <th>Especialidades</th>
                <th>Centros</th>
                <th class="text-end">Citas futuras</th>
                <th class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($medicos as $m): ?>
            <tr>
                <td><strong><?= h($m['nombre']) ?></strong><br>
                    <span class="text-muted small"><?= h($m['rut']) ?> &middot; <?= h($m['email']) ?></span></td>
                <td><?= h($m['especialidades']) ?></td>
                <td><?= h($m['centros']) ?></td>
                <td class="text-end"><?= (int)$m['citas_futuras'] ?></td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-primary"
                       href="admin_medicos.php?editar=<?= urlencode($m['rut']) ?>">Editar</a>
                    <form method="post" action="admin_medicos.php" class="d-inline"
                          onsubmit="return confirm('¿Eliminar a este médico del sistema?');">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="rut_medico" value="<?= h($m['rut']) ?>">
                        <button class="btn btn-sm btn-outline-danger" type="submit">Eliminar</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php if (empty($medicos)): ?>
            <tr><td colspan="5" class="text-center text-muted py-4">No hay médicos registrados.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
