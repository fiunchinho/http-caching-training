<?php
$now = time();
$expiration = $now;

$expiration_seconds = $expiration - $now;
$expiration_date = gmdate( 'D, d M Y H:i:s',  $expiration ).' GMT';

header( 'Expires: '.$expiration_date);
header( 'Cache-Control: public,max-age='.$expiration_seconds );

echo gmdate( 'D, d M Y H:i:s' );
?>