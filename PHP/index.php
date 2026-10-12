<?php
require_once 'funciones.php';

ir_a(hay_sesion() ? 'inicio.php' : 'login.php');
