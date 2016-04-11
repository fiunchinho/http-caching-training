<?php
$my_app_last_update = new DateTime( '2015-07-02 10:00' );

if ( 
		empty( $_SERVER['HTTP_IF_MODIFIED_SINCE'] ) || 
		( strtotime( $_SERVER['HTTP_IF_MODIFIED_SINCE'] ) < strtotime( $my_app_last_update->format( 'D, j M Y H:i:s T' ) ) ) 
	)
{
	header( 'Last-Modified: ' . $my_app_last_update->format( 'D, j M Y H:i:s T' ) );
	echo date('H:i:s');
}
else
{
	header( 'HTTP/1.1 304 Not Modified' );
}
echo "<br /><a href='modified.php'>link</a>";