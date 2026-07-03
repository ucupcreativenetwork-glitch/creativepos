<?php

namespace App\Modules\Auth\Enums;

enum OtpPurpose: string
{
    case Login = 'login';
    case Register = 'register';
    case ResetPassword = 'reset_password';
    case VerifyPhone = 'verify_phone';
    case Transaction = 'transaction';
}