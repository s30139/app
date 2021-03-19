// func

var restorePassword = function(token) {

    var email = $('#restore_username').val();
    var selfUrl = location.protocol + '//' + location.host + location.pathname;

    $.ajax({
        type: "POST",
        dataType: "json",
        url: location.pathname ,
        data: { action: "restore_password" , email: email , reCaptchaResponse: token },
        success: function( response ) {
            console.dir( response );
            if ( response.status == 1 ) {
                $("#loginform-div-restore-form").addClass('hidden');
                $("#loginform-div-restore-form-error").addClass('hidden');
                $("#strong-restore-email-success").html(email);
                $("#loginform-div-restore-form-success").removeClass('hidden');
            }
            if ( response.status == 0 ) {
                $("#loginform-div-restore-form").addClass('hidden');
                $("#loginform-div-restore-form-success").addClass('hidden');
                $("#strong-restore-email-success").html(email);
                $("#loginform-div-restore-form-error").removeClass('hidden');
            }
        }
    });
};

function doLogin(r) {

    console.dir( r );

    if ( r.status == 0 ) {
        location.href = r.url;
        return ;
    }
    wrongCredentials();
    grecaptcha.reset(wIdreCaptchaLogin);
}

function wrongCredentials(){
    $('#login-form-btn'   ).html( 'Войти' );
    $('#login-form-modal' ).shake(3,11,300);
    $('#wrong-credentials').removeClass('hidden');
    setTimeout(function() {
        $('#wrong-credentials').addClass('hidden');
    }, 3000);
}

jQuery.fn.shake = function(intShakes, intDistance, intDuration) {
    this.each(function() {
        $(this).css("position","relative"); 
        for (var x=1; x<=intShakes; x++) {
            $(this).animate({left:(intDistance*-1)}, (((intDuration/intShakes)/4)))
                .animate({left:intDistance}, ((intDuration/intShakes)/2))
                .animate({left:0}, (((intDuration/intShakes)/4)));
        }
    });
    return this;
};

//
function checkEmail(email){
    if( (/^[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-\.]+$/.test(email)) ){
        return true;
    }
    return false;
}

//
function reqPost(data, callback) {
    $.ajax({
        type: "POST",
        dataType: "json",
        url: location.pathname,
        data: data,
        success: function( response ) {
            callback( response );
        }
    });
}
// vue.js
var app = new Vue({
  el: '#login-form-modal',
  data: {
    email: '',
    invalidEmail: false,
    password: '',
    passwordFieldType: 'password',
    loginTabActive: true,
    restoreTabActive: false
  },
  methods: {
    vLogin: function () {
        if ( checkEmail( this.email ) ) {
            this.invalidEmail = false;
            var data = {
                action: "do_login",
                email: this.email,
                password: this.password
            };
            reqPost(data, doLogin);
        } else {
            this.invalidEmail = true;
        }
    },
    showPassword: function() {
        console.dir('showPassword');
        this.passwordFieldType = this.passwordFieldType == 'password' ? 'text' : 'password';
    },
    loginTab: function() {
        console.dir('loginTab');
        this.loginTabActive   = true;
        this.restoreTabActive = false;
    },
    restoreTab: function() {
        console.dir('restoreTab');
        this.loginTabActive   = false;
        this.restoreTabActive = true;
    }
  }

})

//
