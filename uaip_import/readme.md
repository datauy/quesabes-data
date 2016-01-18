# Scripts para importar datos del Catálogo de Datos Abiertos

Este directorio contiene los scripts para normalizar las entidades de la base de datos actual e importar los [datos de los responsables de transparencia del Catálogo de Datos Abiertos publicados por la UAIP](https://catalogodatos.gub.uy/dataset/datos-de-responsables-de-transparencia). [Discusión inicial aquí](https://github.com/datauy/quesabes-theme/issues/26).

# normalize.rb

```bash
cd alaveteli # correr desde el directorio root de la aplicación Rails
bundle exec rails runner normalize.rb
```
