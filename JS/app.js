document.addEventListener('DOMContentLoaded', function () {

    var campoRut = document.getElementById('rut');
    if (campoRut) {
        campoRut.addEventListener('blur', function () {
            campoRut.value = campoRut.value.toUpperCase().trim();
        });
    }

    var avisos = document.querySelectorAll('.alert-success');
    avisos.forEach(function (aviso) {
        setTimeout(function () {
            aviso.classList.remove('show');
        }, 6000);
    });
});
