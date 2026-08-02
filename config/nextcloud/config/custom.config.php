<?php
$CONFIG = [
    'trusted_domains' => [
        '0' => 'localhost:8080',
        '1' => '10.3.152.101:8080',
        // Adicione todos os domínios que usa
    ],
    // Opcional: outras configurações recorrentes
    'filelocking.enabled' => false,
    'memcache.local' => '\OC\Memcache\APCu',
];