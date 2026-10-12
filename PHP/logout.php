<?php
require_once 'funciones.php';

$_SESSION = [];
session_destroy();
session_start();
flash('success', 'Sesión cerrada correctamente.');
ir_a('login.php');
