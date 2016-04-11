<?php

$when_should_expire = new DateTime( '2016-04-12 23:00' );
//$when_should_expire->modify( '-1 hour' );
header('Expires: ' . $when_should_expire->format( 'D, j M Y H:i:s T' ) );
?>
<link href="cache.css" rel="stylesheet" type="text/css">
<?php
echo date("H:i:s");
echo "<br /><a href='expires.php'>link</a>";

