<?PHP

namespace handlers;

use IAM\Sso;
use IAM\Configuration as IAMConfiguration;

use Knight\armor\Output;
use Knight\armor\Navigator;

$uri = parse_url($_SERVER[Navigator::REQUEST_URI], PHP_URL_PATH);
$uri = explode(chr(47), trim($uri, chr(47)));
$uri = array_filter($uri, 'strlen');
$uri = array_values($uri);
$uri_route = array_slice($uri, 1, Navigator::getDepth());
if (Sso::AUTHORIZATION === reset($uri_route)) Sso::auth();

$application_basename = IAMConfiguration::getApplicationBasename();
if (Sso::youHaveNoPolicies($application_basename . chr(47) . 'sync')) Output::print(false);

$higeco_serial = reset($uri);
if (false === $higeco_serial
    || preg_match('/\W+/i', $higeco_serial)) Output::print(false);

$location = Navigator::getProtocol() . chr(58) . chr(47) . chr(47) . $_SERVER[Navigator::HTTP_HOST] . chr(47) . 'get' . chr(47) . $higeco_serial;
Navigator::noCache();
header('HTTP/1.1 301 Moved Permanently');
header('Location' . chr(58) . chr(32) . $location);
exit;