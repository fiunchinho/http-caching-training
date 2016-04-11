<?php
$etag = '1234567';
if ( 
		!empty( $_SERVER['HTTP_IF_NONE_MATCH'] ) && 
		( $_SERVER['HTTP_IF_NONE_MATCH'] == $etag )
	)
{
	header( 'HTTP/1.1 304 Not Modified' );
}
else
{
	header( 'ETag: ' . $etag );
	echo date('H:i:s');
	echo "<br /><a href='etag.php'>link</a>";
}