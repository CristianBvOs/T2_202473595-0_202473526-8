<?php
require_once 'funciones.php';
requiere_rol([ROL_ADMIN]);

$titulo = 'Panel de gestión';

$centros = $pdo->query("SELECT c.id_centro,
                               c.codigo,
                               c.nombre,
                               co.nombre AS comuna,
                               r.nombre  AS region,
                               COUNT(ci.id_cita) AS total_citas,
                               SUM(e.nombre = 'No Asistió') AS inasistencias,
                               fn_porcentaje_inasistencia(c.id_centro) AS porcentaje
                        FROM      centro_medico c
                        JOIN      comuna      co ON co.id_comuna = c.id_comuna
                        JOIN      region      r  ON r.id_region  = co.id_region
                        LEFT JOIN cita        ci ON ci.id_centro = c.id_centro
                        LEFT JOIN estado_cita e  ON e.id_estado  = ci.id_estado
                        GROUP BY  c.id_centro, c.codigo, c.nombre, co.nombre, r.nombre
                        ORDER BY  porcentaje DESC")->fetchAll();

$top = $pdo->query('SELECT d.codigo_cie10,
                           d.descripcion,
                           COUNT(*) AS veces
                    FROM   atencion_diagnostico ad
                    JOIN   diagnostico d ON d.id_diagnostico = ad.id_diagnostico
                    GROUP BY d.id_diagnostico, d.codigo_cie10, d.descripcion
                    ORDER BY veces DESC, d.codigo_cie10
                    LIMIT 5')->fetchAll();

$totales = $pdo->query("SELECT COUNT(*) AS citas,
                               SUM(e.nombre = 'No Asistió') AS inasistencias,
                               SUM(e.nombre = 'Atendida')   AS atendidas
                        FROM   cita c
                        JOIN   estado_cita e ON e.id_estado = c.id_estado")->fetch();

require 'cabecera.php';
?>

<h1 class="h4 mb-3">Panel de gestión</h1>

<div class="row g-3 mb-4">
    <div class="col-md-4">
        <div class="card text-center"><div class="card-body">
            <div class="display-6"><?= (int)$totales['citas'] ?></div>
            <div class="text-muted">Citas en la red</div>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center"><div class="card-body">
            <div class="display-6"><?= (int)$totales['atendidas'] ?></div>
            <div class="text-muted">Citas atendidas</div>
        </div></div>
    </div>
    <div class="col-md-4">
        <div class="card text-center"><div class="card-body">
            <div class="display-6"><?= (int)$totales['inasistencias'] ?></div>
            <div class="text-muted">Inasistencias</div>
        </div></div>
    </div>
</div>

<h2 class="h6 mb-2">Citas e inasistencia por centro médico</h2>
<div class="table-responsive mb-4">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th>Código</th>
                <th>Centro</th>
                <th>Comuna / Región</th>
                <th class="text-end">Total de citas</th>
                <th class="text-end">No Asistió</th>
                <th style="width:220px">% de inasistencia</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($centros as $c): ?>
            <tr>
                <td><?= h($c['codigo']) ?></td>
                <td><?= h($c['nombre']) ?></td>
                <td><?= h($c['comuna']) ?><br>
                    <span class="text-muted small"><?= h($c['region']) ?></span></td>
                <td class="text-end"><?= (int)$c['total_citas'] ?></td>
                <td class="text-end"><?= (int)$c['inasistencias'] ?></td>
                <td>
                    <div class="d-flex align-items-center gap-2">
                        <div class="progress flex-grow-1" style="height:10px">
                            <div class="progress-bar bg-<?= $c['porcentaje'] > 15 ? 'danger' : 'success' ?>"
                                 style="width: <?= min(100, (float)$c['porcentaje']) ?>%"></div>
                        </div>
                        <span class="small"><?= number_format((float)$c['porcentaje'], 2) ?>%</span>
                    </div>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</div>

<h2 class="h6 mb-2">Los 5 diagnósticos más frecuentes de la red</h2>
<div class="table-responsive">
    <table class="table table-hover align-middle bg-white">
        <thead class="table-light">
            <tr>
                <th style="width:60px">#</th>
                <th style="width:140px">Código CIE-10</th>
                <th>Descripción</th>
                <th class="text-end">Veces registrado</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($top as $i => $d): ?>
            <tr>
                <td><?= $i + 1 ?></td>
                <td><span class="badge bg-secondary"><?= h($d['codigo_cie10']) ?></span></td>
                <td><?= h($d['descripcion']) ?></td>
                <td class="text-end"><?= (int)$d['veces'] ?></td>
            </tr>
        <?php endforeach; ?>
        <?php if (empty($top)): ?>
            <tr><td colspan="4" class="text-center text-muted py-4">Todavía no hay diagnósticos registrados.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</div>

<?php require 'pie.php'; ?>
