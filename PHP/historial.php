<?php
require_once 'funciones.php';
requiere_rol([ROL_PACIENTE, ROL_MEDICO]);

$titulo = 'Historial clínico';
$rut_paciente = trim($_GET['rut_paciente'] ?? '');
$pacientes = [];

if (es_paciente()) {

    $rut_paciente = rut_actual();
} else {

    $st = $pdo->prepare('SELECT DISTINCT u.rut, u.nombre
                         FROM   cita c
                         JOIN   usuario u ON u.rut = c.rut_paciente
                         WHERE  c.rut_medico = ?
                         ORDER BY u.nombre');
    $st->execute([rut_actual()]);
    $pacientes = $st->fetchAll();

    if ($rut_paciente !== '') {
        $permitido = false;
        foreach ($pacientes as $p) {
            if ($p['rut'] === $rut_paciente) {
                $permitido = true;
                break;
            }
        }
        if (!$permitido) {
            flash('danger', 'Solo puede consultar el historial de pacientes que han tenido citas con usted.');
            ir_a('historial.php');
        }
    }
}

$atenciones = [];
$paciente_nombre = '';
if ($rut_paciente !== '') {
    $st = $pdo->prepare('SELECT nombre FROM usuario WHERE rut = ?');
    $st->execute([$rut_paciente]);
    $paciente_nombre = (string)$st->fetchColumn();

    $st = $pdo->prepare("SELECT a.*,
                (SELECT GROUP_CONCAT(CONCAT(d.codigo_cie10, ' - ', d.descripcion)
                                     ORDER BY d.codigo_cie10 SEPARATOR ' | ')
                   FROM atencion_diagnostico ad
                   JOIN diagnostico d ON d.id_diagnostico = ad.id_diagnostico
                  WHERE ad.id_atencion = a.id_atencion) AS diagnosticos,
                (SELECT GROUP_CONCAT(CONCAT(r.medicamento, ' (', r.dosis, ', ',
                                            r.dias_tratamiento, ' día(s))')
                                     ORDER BY r.id_receta SEPARATOR ' | ')
                   FROM receta r
                  WHERE r.id_atencion = a.id_atencion) AS recetas
            FROM   vw_atencion_detalle a
            WHERE  a.rut_paciente = ?
            ORDER BY a.fecha DESC, a.hora_inicio DESC");
    $st->execute([$rut_paciente]);
    $atenciones = $st->fetchAll();
}

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Historial clínico</h1>

<?php if (es_medico()): ?>
    <form class="row g-2 align-items-end mb-4" method="get" action="historial.php">
        <div class="col-md-6">
            <label class="form-label" for="rut_paciente">Paciente</label>
            <select class="form-select" id="rut_paciente" name="rut_paciente" onchange="this.form.submit()">
                <option value="">Seleccione un paciente...</option>
                <?php foreach ($pacientes as $p): ?>
                    <option value="<?= h($p['rut']) ?>" <?= $rut_paciente === $p['rut'] ? 'selected' : '' ?>>
                        <?= h($p['nombre']) ?> (<?= h($p['rut']) ?>)
                    </option>
                <?php endforeach; ?>
            </select>
        </div>
    </form>
<?php endif; ?>

<?php if ($rut_paciente === ''): ?>
    <div class="alert alert-info">Seleccione un paciente para ver sus atenciones anteriores.</div>
<?php else: ?>
    <p class="text-muted">
        <?= count($atenciones) ?> atención(es) registradas para <?= h($paciente_nombre) ?>.
    </p>

    <?php foreach ($atenciones as $a): ?>
        <div class="card mb-3">
            <div class="card-header d-flex justify-content-between">
                <span>
                    <strong><?= fecha_cl($a['fecha']) ?></strong> &middot;
                    <?= h($a['especialidad']) ?> &middot; <?= h($a['medico']) ?>
                </span>
                <span class="text-muted small"><?= h($a['centro']) ?></span>
            </div>
            <div class="card-body">
                <p class="mb-2"><strong>Motivo:</strong> <?= h($a['motivo']) ?></p>
                <?php if ($a['observaciones']): ?>
                    <p class="mb-2"><strong>Observaciones:</strong> <?= h($a['observaciones']) ?></p>
                <?php endif; ?>
                <p class="mb-2"><strong>Diagnósticos:</strong>
                    <?= $a['diagnosticos'] ? h($a['diagnosticos']) : '<span class="text-muted">sin diagnósticos</span>' ?>
                </p>
                <p class="mb-0"><strong>Receta:</strong>
                    <?= $a['recetas'] ? h($a['recetas']) : '<span class="text-muted">sin medicamentos</span>' ?>
                </p>
            </div>
            <?php if (es_medico() && $a['rut_medico'] === rut_actual()): ?>
                <div class="card-footer text-end">
                    <a class="btn btn-sm btn-outline-primary"
                       href="atencion.php?id_cita=<?= (int)$a['id_cita'] ?>">Editar atención</a>
                </div>
            <?php endif; ?>
        </div>
    <?php endforeach; ?>

    <?php if (empty($atenciones)): ?>
        <div class="alert alert-secondary">Este paciente aún no tiene atenciones registradas.</div>
    <?php endif; ?>
<?php endif; ?>

<?php require 'pie.php'; ?>
