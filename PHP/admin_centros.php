<?php
require_once 'funciones.php';
requiere_rol([ROL_ADMIN]);

$titulo = 'Centros médicos';

$id_editar = (int)($_GET['editar'] ?? $_POST['id_centro'] ?? 0);
$centro = ['id_centro' => 0, 'codigo' => '', 'nombre' => '', 'id_comuna' => ''];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = $_POST['accion'] ?? '';

    if ($accion === 'eliminar') {
        $st = $pdo->prepare('SELECT COUNT(*) FROM cita WHERE id_centro = ?');
        $st->execute([$id_editar]);
        if ($st->fetchColumn() > 0) {
            flash('danger', 'No se puede eliminar el centro: tiene citas registradas. '
                          . 'Primero debe reasignar o eliminar esas citas.');
        } else {
            try {
                $st = $pdo->prepare('DELETE FROM centro_medico WHERE id_centro = ?');
                $st->execute([$id_editar]);
                flash('success', 'Centro médico eliminado.');
            } catch (PDOException $e) {
                flash('danger', mensaje_bd($e));
            }
        }
        ir_a('admin_centros.php');

    } elseif ($accion === 'guardar') {
        $centro['codigo']    = strtoupper(trim($_POST['codigo'] ?? ''));
        $centro['nombre']    = trim($_POST['nombre'] ?? '');
        $centro['id_comuna'] = (int)($_POST['id_comuna'] ?? 0);
        $errores = [];

        if ($centro['codigo'] === '')   { $errores[] = 'El código del centro es obligatorio.'; }
        if ($centro['nombre'] === '')   { $errores[] = 'El nombre del centro es obligatorio.'; }
        if ($centro['id_comuna'] === 0) { $errores[] = 'Debe seleccionar la comuna.'; }

        if (empty($errores)) {
            try {
                if ($id_editar > 0) {
                    $st = $pdo->prepare('UPDATE centro_medico
                                         SET codigo = ?, nombre = ?, id_comuna = ?
                                         WHERE id_centro = ?');
                    $st->execute([$centro['codigo'], $centro['nombre'],
                                  $centro['id_comuna'], $id_editar]);
                    flash('success', 'Centro médico actualizado.');
                } else {
                    $st = $pdo->prepare('INSERT INTO centro_medico (codigo, nombre, id_comuna)
                                         VALUES (?, ?, ?)');
                    $st->execute([$centro['codigo'], $centro['nombre'], $centro['id_comuna']]);
                    flash('success', 'Centro médico creado.');
                }
                ir_a('admin_centros.php');
            } catch (PDOException $e) {
                $errores[] = mensaje_bd($e);
            }
        }

        foreach ($errores as $m) {
            flash('danger', $m);
        }
    }
}

if ($id_editar > 0 && $_SERVER['REQUEST_METHOD'] === 'GET') {
    $st = $pdo->prepare('SELECT * FROM centro_medico WHERE id_centro = ?');
    $st->execute([$id_editar]);
    $encontrado = $st->fetch();
    if (!$encontrado) {
        flash('danger', 'El centro médico indicado no existe.');
        ir_a('admin_centros.php');
    }
    $centro = $encontrado;
}

$comunas = $pdo->query('SELECT c.id_comuna, c.nombre, r.nombre AS region
                        FROM comuna c JOIN region r ON r.id_region = c.id_region
                        ORDER BY r.nombre, c.nombre')->fetchAll();

$centros = $pdo->query('SELECT c.id_centro, c.codigo, c.nombre,
                               co.nombre AS comuna, r.nombre AS region,
                               (SELECT COUNT(*) FROM medico_centro mc
                                 WHERE mc.id_centro = c.id_centro) AS medicos,
                               (SELECT COUNT(*) FROM cita ci
                                 WHERE ci.id_centro = c.id_centro) AS citas
                        FROM   centro_medico c
                        JOIN   comuna co ON co.id_comuna = c.id_comuna
                        JOIN   region r  ON r.id_region  = co.id_region
                        ORDER BY c.codigo')->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Centros médicos</h1>

<div class="card mb-4">
    <div class="card-header"><?= $id_editar ? 'Editar centro médico' : 'Nuevo centro médico' ?></div>
    <div class="card-body">
        <form method="post" action="admin_centros.php" class="row g-3">
            <input type="hidden" name="accion" value="guardar">
            <input type="hidden" name="id_centro" value="<?= (int)$id_editar ?>">
            <div class="col-md-2">
                <label class="form-label" for="codigo">Código</label>
                <input type="text" class="form-control" id="codigo" name="codigo" maxlength="10"
                       value="<?= h($centro['codigo']) ?>" placeholder="CM-006" required>
            </div>
            <div class="col-md-5">
                <label class="form-label" for="nombre">Nombre del centro</label>
                <input type="text" class="form-control" id="nombre" name="nombre" maxlength="80"
                       value="<?= h($centro['nombre']) ?>" required>
            </div>
            <div class="col-md-3">
                <label class="form-label" for="id_comuna">Comuna (define la región)</label>
                <select class="form-select" id="id_comuna" name="id_comuna" required>
                    <option value="">Seleccione...</option>
                    <?php foreach ($comunas as $c): ?>
                        <option value="<?= (int)$c['id_comuna'] ?>"
                            <?= $centro['id_comuna'] == $c['id_comuna'] ? 'selected' : '' ?>>
                            <?= h($c['nombre']) ?> (<?= h($c['region']) ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-2 d-flex align-items-end gap-2">
                <button class="btn btn-salud flex-grow-1" type="submit">Guardar</button>
                <?php if ($id_editar): ?>
                    <a class="btn btn-outline-secondary" href="admin_centros.php">Cancelar</a>
                <?php endif; ?>
            </div>
        </form>
    </div>
</div>

<div class="table-responsive">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Código</th>
                <th>Nombre</th>
                <th>Comuna</th>
                <th>Región</th>
                <th class="text-end">Médicos</th>
                <th class="text-end">Citas</th>
                <th class="text-end">Acciones</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($centros as $c): ?>
            <tr>
                <td><?= h($c['codigo']) ?></td>
                <td><?= h($c['nombre']) ?></td>
                <td><?= h($c['comuna']) ?></td>
                <td><?= h($c['region']) ?></td>
                <td class="text-end"><?= (int)$c['medicos'] ?></td>
                <td class="text-end"><?= (int)$c['citas'] ?></td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-primary"
                       href="admin_centros.php?editar=<?= (int)$c['id_centro'] ?>">Editar</a>
                    <form method="post" action="admin_centros.php" class="d-inline"
                          onsubmit="return confirm('¿Eliminar este centro médico?');">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="id_centro" value="<?= (int)$c['id_centro'] ?>">
                        <button class="btn btn-sm btn-outline-danger" type="submit">Eliminar</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php if (empty($centros)): ?>
            <tr><td colspan="7" class="text-center text-muted py-4">No hay centros registrados.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
