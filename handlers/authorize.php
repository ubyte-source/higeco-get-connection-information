<?PHP

namespace handlers;

use IAM\Sso;
use IAM\Request;
use IAM\Configuration as IAMConfiguration;

use Redis\Cache;

use Knight\armor\Output;
use Knight\armor\Request as KRequest;

$application_basename = IAMConfiguration::getApplicationBasename();
$authorizing_token = KRequest::header(Request::HEADER_AUTHOTIZATION);
if (null === $authorizing_token) Sso::unauthorized(false);

Cache::get(__file__, $authorizing_token, function () use ($application_basename) {
    if (false === Sso::requestMandatoryPolicies($application_basename . chr(47) . 'sync')) Sso::unauthorized(false);
    return true;
});
Output::print(true);
