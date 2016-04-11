<?php
header('Cache-Control: public, max-age=60');
echo date("H:i:s");
echo "<br /><a href='maxage.php'>link</a>";