# ios-udid-reader

Sitio web para obtener el UDID de un iPhone mediante un perfil de configuración
temporal y una función de Vercel.

## Firmar el perfil

Se necesita OpenSSL 1.1.1 o posterior. Desde la raíz del proyecto, ejecuta:

```sh
./sign-profile.sh
```

El script crea una CA y firma `public/profile.mobileconfig`. La clave privada se
guarda fuera del repositorio en `~/.config/ios-udid-reader/ca.key`; únicamente
el certificado público `public/myCA.pem` y el perfil firmado
`public/profile_signed.mobileconfig` se publican. **Nunca copies la clave
privada a `public/` ni la subas a GitHub.**

Conserva una copia segura de la clave privada. Si se pierde, al ejecutar el
script se crea una CA nueva y cada iPhone tendrá que instalar y confiar en el
nuevo certificado.

## Uso desde el iPhone

1. Abre el sitio en Safari y descarga el certificado.
2. En Ajustes, instala el perfil descargado.
3. En Ajustes > General > Información > Ajustes de confianza de los
   certificados, activa la confianza total del certificado de esta aplicación.
4. Vuelve a Safari, confirma que completaste el paso y descarga el perfil para
   solicitar el UDID.
5. Instálalo desde Ajustes > Perfil descargado. Al terminar, Safari vuelve a
   mostrar el UDID.
6. Elimina el perfil temporal y el certificado si ya no los necesitas.

iOS no permite que la página compruebe si el certificado se instaló o si se
activó la confianza; la confirmación del paso es manual. iOS puede mostrar
«Perfil descargado» tanto para el certificado como para el perfil. Ese aviso
no confirma que sean el mismo archivo.
