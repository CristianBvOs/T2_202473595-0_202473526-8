<?php
require_once 'funciones.php';
requiere_rol();

$titulo = 'Buscar médicos';
$q = trim($_GET['q'] ?? '');

$sql = "SELECT u.rut,
               u.nombre,
               u.email,
               (SELECT GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ')
                  FROM medico_especialidad me
                  JOIN especialidad e ON e.id_especialidad = me.id_especialidad
                 WHERE me.rut_medico = m.rut) AS especialidades,
               (SELECT GROUP_CONCAT(c.nombre ORDER BY c.nombre SEPARATOR ', ')
                  FROM medico_centro mc
                  JOIN centro_medico c ON c.id_centro = mc.id_centro
                 WHERE mc.rut_medico = m.rut) AS centros
        FROM   medico  m
        JOIN   usuario u ON u.rut = m.rut";

$parametros = [];
if ($q !== '') {
    $sql .= " WHERE u.nombre LIKE ?
                 OR EXISTS (SELECT 1
                              FROM medico_especialidad me2
                              JOIN especialidad e2 ON e2.id_especialidad = me2.id_especialidad
                             WHERE me2.rut_medico = m.rut
                               AND e2.nombre LIKE ?)";
    $parametros = ['%' . $q . '%', '%' . $q . '%'];
}
$sql .= ' ORDER BY u.nombre';

$st = $pdo->prepare($sql);
$st->execute($parametros);
$medicos = $st->fetchAll();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Buscar médicos</h1>

<form class="row g-2 mb-4" method="get" action="buscar_medicos.php">
    <div class="col-md-9">
        <input type="text" class="form-control" name="q" value="<?= h($q) ?>"
               placeholder="Nombre del médico o especialidad (por ejemplo: Rojas, Pediatría)">
    </div>
    <div class="col-md-3 d-grid">
        <button class="btn btn-salud" type="submit">Buscar</button>
    </div>
</form>

<?php if ($q !== ''): ?>
    <p class="text-muted"><?= count($medicos) ?> resultado(s) para "<?= h($q) ?>".</p>
<?php endif; ?>

<div class="table-responsive">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Médico</th>
                <th>Especialidades</th>
                <th>Centros donde atiende</th>
                <?php if (es_paciente()): ?><th></th><?php endif; ?>
            </tr>
        </thead>
        <tbody>
        <?php if (empty($medicos)): ?>
            <tr><td colspan="4" class="text-center text-muted py-4">
                No se encontraron médicos con ese criterio.
            </td></tr>
        <?php endif; ?>
        <?php foreach ($medicos as $m): ?>
            <tr>
                <td>
                    <strong><?= h($m['nombre']) ?></strong><br>
                    <span class="text-muted small"><?= h($m['rut']) ?> &middot; <?= h($m['email']) ?></span>
                </td>
                <td><?= h($m['especialidades']) ?></td>
                <td><?= h($m['centros']) ?></td>
                <?php if (es_paciente()): ?>
                    <td class="text-end">
                        <a class="btn btn-sm btn-outline-primary"
                           href="agendar_hora.php?rut_medico=<?= urlencode($m['rut']) ?>">Agendar</a>
                    </td>
                <?php endif; ?>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
