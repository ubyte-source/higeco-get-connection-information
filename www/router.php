<?PHP

namespace www;

require_once dirname(dirname(__FILE__)) . DIRECTORY_SEPARATOR . 'boot.php';

const SECURE = [
    'php'
];

use Knight\armor\Output;
use Knight\armor\Cookie;
use Knight\armor\Navigator;

$client = Navigator::getClientIP();
$client = long2ip($client);

if (!!filter_var($client, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 | FILTER_FLAG_NO_PRIV_RANGE) && Cookie::getSecure() && 'http' === Navigator::getProtocol()) {
    $location = 'https://' . $_SERVER[Navigator::HTTP_HOST] . $_SERVER[Navigator::REQUEST_URI];
    Navigator::noCache();
    header('HTTP/1.1 301 Moved Permanently');
    header('Location' . chr(58) . chr(32) . $location);
    exit;
}

$handler = parse_url($_SERVER[Navigator::REQUEST_URI], PHP_URL_PATH);
$handler_match = dirname($handler);
$handler_match_secure = implode(chr(124), SECURE);
if (preg_match('/\.(' . $handler_match_secure . ')/', $handler_match)) Output::print(false);
include BASE_HANDLERS . 'authorize' . chr(46) . 'php';
exit;
