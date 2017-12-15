# Count total lines of code across a GitHub organization

## Usage

1. `git clone https://github.com/benbalter/count-org-loc && cd count-org-loc`
2. `gem install bundler`
3. `script/bootstrap`
4. `script/count [ORG_NAME]`

## How it works

It uses [Octokit.rb](https://github.com/octokit/octokit.rb) to fetch a list of your organization's repositories (public or public and private), and [Cloc](https://github.com/AlDanial/cloc) to count the lines of code, number of files, comments, etc.

## Example output for @whitehouse

```
-------------------------------------------------------------------------------
File                         files          blank        comment           code
-------------------------------------------------------------------------------
petitions                      247           5981          20274          28748
wh-app-ios                     202           6929           7409          23451
fitara                         112            711            481          10693
cyber-acquisitions             110            709            490          10400
omb_place                      163            781            972           8684
wh-app-android                 123           1384            307           8382
fortyfour                       51            591            702           3902
education-compliance-reports     3            192              4           2964
choropleth                       8            320            669           2579
choropleth_dataset              14             93            508            841
drushsubtree                     4            220            887            834
services_documentation          18            154            563            746
buildmanager                     3             95            400            302
petitionssignatureform           3             19             48            184
shunt                            3             42            183            130
petitions-php-sdk                1             42            151            127
tweetfetch                       3             29             74            125
tweetserver                      3             30             74            109
twitterapi                       3             21             70             59
petitions_thermometer            1              0              0             56
netstorage                       1             16             70             45
logger                           2             10             46             29
webform_submit_button            1              6             21             20
-------------------------------------------------------------------------------
SUM:                          1079          18375          34403         103410
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
Language                      files          blank        comment           code
--------------------------------------------------------------------------------
CSS                              64           1984           1670          25321
Objective C                      90           4910           2244          20331
SASS                            242           3013           1045          16512
Pascal                          129           3079          20164          11263
Javascript                       71            931           1519           8304
Java                             66           1116            246           6882
JSON                            125            182              0           5380
PHP                              82            565           1914           3519
C/C++ Header                    102           1979           5153           2545
HTML                             32            209            258           1471
XML                              47            149             28            920
Bourne Shell                      9             95             70            376
Groovy                            5             22              4            140
Bourne Again Shell                1             20             21            123
Prolog                            2             25              0             74
Ruby                              6             25             31             69
DOS Batch                         1             24              2             64
Python                            1             25              4             63
YAML                              4             22             30             53
--------------------------------------------------------------------------------
SUM:                           1079          18375          34403         103410
--------------------------------------------------------------------------------
```

## Counting private repositories

To look at private repositories, you'll need to pass a [personal access token](https://github.com/settings/tokens/new) with `repo` scope as `GITHUB_TOKEN`. You can do this by adding `GITHUB_TOKEN=[TOKEN]` to a `.env` file in the repository's root.

If you are working with GitHub Enterprise and want to change your URL, simply add `GITHUB_ENTERPRISE_URL=https://<ghe-url>/api/v3` to the `.env` file

```
Sample `.env` File
```bash
GITHUB_TOKEN="<token>"
GITHUB_ENTERPRISE_URL="https://my-ghe.local/api/v3"
```