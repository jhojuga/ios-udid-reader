# ios-udid-reader

Sitio web para obtener el UDID de un iPhone mediante un perfil de configuración
temporal y una función de Vercel.

## Firma recomendada para iPhone real

Para evitar errores como “Perfil no válido”, firma
`public/profile.mobileconfig` con un certificado **leaf** y una cadena de
confianza pública para iOS (no con una CA local autofirmada).

Desde la raíz del proyecto:

```sh
sh ./sign-profile-public.sh /ruta/signer.crt /ruta/signer.key /ruta/chain.pem
```

Parámetros:

1. `signer.crt`: certificado leaf que firma el perfil.
2. `signer.key`: llave privada del certificado leaf.
3. `chain.pem`: cadena intermedia (sin incluir la raíz).

El script genera `public/profile_signed.mobileconfig` y verifica su estructura
CMS. **Nunca subas llaves privadas al repositorio.**

## Firma local de pruebas (opcional)

`sign-profile.sh` conserva una firma con CA local para pruebas de laboratorio.
En iPhone real puede seguir mostrando “Perfil no válido”, por eso no es el
flujo recomendado para producción.

## Uso desde el iPhone

1. Abre el sitio en Safari y descarga el perfil de UDID.
2. En Ajustes > Perfil descargado, instala el perfil.
3. Safari vuelve a la página y muestra el UDID.
4. Elimina el perfil temporal al terminar.
