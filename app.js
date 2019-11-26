const express = require('express');
const database = require('./database');
const connectionName = 'BibliotecaCine';
const bodyParser = require('body-parser');


const app = express();
const router = express.Router();
const port = process.env.PORT || 3000;
process.env.UV_THREADPOOL_SIZE = 3;

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

router.route('/peliculas')
    .get(async (req, res) => {
        const cantidad = `SELECT COUNT(*) as Peliculas_Disponibles
        FROM PELICULAS`;
        const peliculas = `SELECT ID_PELICULA, TITULO
        FROM PELICULAS`;
        const canciones = `SELECT id_pelicula, nombre_banda, song_name
        FROM bandasonora_pelicula natural join audios natural join cancion_banda`;
        try {
            const result1 = await database.simpleExecute(connectionName, cantidad, []);
            const result2 = await database.simpleExecute(connectionName, peliculas, []);
            const result3 = await database.simpleExecute(connectionName, canciones, []);
            let format = [];
            let bands = [];
            let songs = [];
            for (let i = 0; i < result1.rows[0].PELICULAS_DISPONIBLES; i++) {
                const movie = result2.rows[i].TITULO;
                for (let j = 0; j < result3.rows.length; j++) {
                    if (result3.rows[j].ID_PELICULA == result2.rows[i].ID_PELICULA) {
                        if (songs.length > 0) {
                            let isRepeat = false;
                            for (let l = 0; l < songs.length; l++) {
                                if (result3.rows[j].SONG_NAME == songs[l]) {
                                    isRepeat = true;
                                }
                            }
                            if (!isRepeat) {
                                songs.push(result3.rows[j].SONG_NAME);
                            }
                        } else {
                            songs.push(result3.rows[j].SONG_NAME);
                        }

                        if (bands.length > 0) {
                            for (let k = 0; k < bands.length; k++) {
                                let isRepeat = false;
                                if (bands[k] == result3.rows[j].NOMBRE_BANDA) {
                                    isRepeat = true;
                                }
                                if (!isRepeat) {
                                    bands.push(result3.rows[j].NOMBRE_BANDA);
                                }
                            }
                        } else {
                            bands.push(result3.rows[j].NOMBRE_BANDA);
                        }
                    }
                }
                format.push({
                    Pelicula: movie,
                    Banda_Sonora: bands,
                    Canciones: songs
                });
                bands = [];
                songs = [];
            }
            const result = {
                Cantidad: result1.rows,
                Informacion: format
            }
            res.json(result);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {
        try {

            //Validaciones para generar el ID (tochemente)
            const cantidad = await database.simpleExecute(connectionName, `SELECT COUNT(*) as Peliculas_Disponibles
            FROM PELICULAS`, []);
            let conteo = (cantidad.rows[0].PELICULAS_DISPONIBLES) + 1;
            let newID;
            if (conteo < 10) {
                newID = `P000${conteo}`;
            }
            if (conteo > 10 && conteo < 100) {
                newID = `P00${conteo}`;
            }
            if (conteo > 100 && conteo < 1000) {
                newID = `P0${conteo}`;
            }
            if (conteo > 1000 && conteo < 10000) {
                newID = `P${conteo}`;
            }

            //Validacion para el ID del director
            let director = req.body.ID_DIRECTOR;
            let exist = false;
            if (director && director.length == 5 && director[0] == "D") {
                const directores = await database.simpleExecute(connectionName, `SELECT ID_DIRECTOR
            FROM DIRECTOR`, []);
                (directores.rows).forEach(element => {
                    if (element.ID_DIRECTOR == `${director}`) {
                        exist = true;
                    }
                });
                if (exist == false) {
                    //Crear un nuevo director
                    const nuevo = await database.simpleExecute(connectionName, `INSERT INTO DIRECTOR 
                (ID_DIRECTOR, NOMBRE, EDAD) VALUES ('${director}', '${req.body.NOMBRE_DIRECTOR || "No definido"}', ${req.body.EDAD_DIRECTOR || 00})`, []);
                    console.log(nuevo);
                }
            } else {
                director = "D0001";
            }

            //Validacion para subir un docsito
            let guiones = req.body.GUIONES;
            let doc = undefined;
            if (guiones) {
                doc = guiones;
            }
            guiones = "ORDSYS.ORDDOC()";

            //Validacion de la cambos nulleables
            let duracion = req.body.DURACION;
            if (!duracion) {
                duracion = null;
            }

            const movie = {
                ID_PELICULA: `${newID}`,
                TITULO: req.body.TITULO,
                ID_DIRECTOR: `${director}`,
                DESCRIPCION: req.body.DESCRIPCION,
                DURACION: duracion,
                CREDITOS: "NULL",
                GUIONES: `${guiones}`
            }

            const insertSql =
                `INSERT INTO PELICULAS (ID_PELICULA, TITULO, ID_DIRECTOR, DESCRIPCION, DURACION, CREDITOS, GUIONES) 
                VALUES ('${movie.ID_PELICULA}', '${movie.TITULO}', '${movie.ID_DIRECTOR}', '${movie.DESCRIPCION}', 
                ${movie.DURACION}, ${movie.CREDITOS}, ${movie.GUIONES})`;
            const result = await database.simpleExecute(connectionName, insertSql, []);
            console.log(result);

            if (doc) { //Si hay un documento
                const procedure =
                    `create or replace procedure Insertar_DocsBD(vCodigo CHAR, vArchivo varchar2) IS
                    doc ordsys.orddoc;
                    ctx raw(64) := null;
                BEGIN
                    SELECT guiones INTO doc FROM PELICULAS
                    WHERE id_pelicula = vCodigo FOR UPDATE;
                    DBMS_OUTPUT.PUT_LINE('setting and getting source');
                    DBMS_OUTPUT.PUT_LINE('--------------------------');
                    -- set source to a file
                    -- import data
                    doc.importFrom(ctx, 'file', 'MULTIMEDIA', vArchivo, FALSE);
                    -- check size
                    DBMS_OUTPUT.PUT_LINE('Length:' ||TO_CHAR(DBMS_LOB.getLength(doc.getContent())));
                    UPDATE PELICULAS SET guiones=doc WHERE id_pelicula=vCodigo;
                    COMMIT;
                    EXCEPTION
                    WHEN ORDSYS.ORDSourceExceptions.METHOD_NOT_SUPPORTED THEN
                        DBMS_OUTPUT.PUT_LINE('ORDSourceExceptions.METHOD_NOT_SUPPORTED caught');
                    WHEN ORDSYS.ORDDocExceptions.DOC_PLUGIN_EXCEPTION THEN
                        DBMS_OUTPUT.put_line('DOC PLUGIN EXCEPTION caught');
                END;
                `;
                const createProcedure = await database.simpleExecute(connectionName, procedure, []);
                const llamada = `BEGIN Insertar_DocsBD('${movie.ID_PELICULA}','${doc}'); END;`;
                const llamarProcedure = await database.simpleExecute(connectionName, llamada, []);
            }

            res.sendStatus(200);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    });

router.route('/peliculas/guiones')
    .get(async (req, res) => {
        const guiones = `SELECT COUNT(*) as Guiones_Disponibles
        FROM PELICULAS`;
        const peliculas = `SELECT ID_PELICULA, TITULO
        FROM PELICULAS`;
        try {
            const result1 = await database.simpleExecute(connectionName, guiones, []);
            const result2 = await database.simpleExecute(connectionName, peliculas, []);
            const result = {
                Cantidad: result1.rows,
                Guiones: result2.rows
            }
            res.json(result);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {
        try {
            const doc = req.body.DOC;
            const id = req.body.ID;
            if (doc && id) {
                //Validaciones para el id de la pelicula
                const IDs = await database.simpleExecute(connectionName, `SELECT ID_PELICULA
            FROM PELICULAS`, []);
                let exist = false;
                for (let i = 0; i < IDs.rows.length; i++) {
                    if (IDs.rows[i].ID_PELICULA == id) {
                        exist = true;
                    }
                }
                if (!exist) {
                    res.json('El ID de la pelicula no es válido');
                }

                //Validaciones para el documento
                const ext = doc.split(".");
                if (ext[1] != "doc" && ext[1] != "docx") {
                    res.json('La extensión del documento donde se exportará no es válido');
                }

                const procedure =
                    `CREATE OR REPLACE PROCEDURE doc_export(
                source_id CHAR,
                filename  VARCHAR2)
            AS
              docSrc ordsys.orddoc;
              ctx raw(64) := NULL;
            BEGIN
              SELECT guiones INTO docSrc FROM PELICULAS WHERE id_pelicula = source_id;
              docSrc.export(ctx, 'FILE', 'EXPORTADO', filename);
            END; `;

                const llamada = `BEGIN doc_export('${id}','${doc}'); END;`;

                const createProcedure = await database.simpleExecute(connectionName, procedure, []);
                const exportar = await database.simpleExecute(connectionName, llamada, []);
                res.sendStatus(200);
            } else {
                res.json('Faltan componentes necesarios para la descarga');
            }
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    });

router.route('/peliculas/imagenes')
    .get(async (req, res) => {
        const cantImg = `SELECT COUNT(*) as Imagenes_Disponibles
        FROM IMAGENES`;
        const cantPelis = `SELECT ID_PELICULA, TITULO
        FROM PELICULAS`;
        const fotos = `SELECT *
        FROM foto_pelicula`;
        try {
            const result1 = await database.simpleExecute(connectionName, cantPelis, []);
            const result3 = await database.simpleExecute(connectionName, cantImg, []);
            const result2 = await database.simpleExecute(connectionName, fotos, []);
            let format = [];
            let images = [];
            for (let i = 0; i < result1.rows.length; i++) {
                const movie = result1.rows[i].TITULO;
                for (let j = 0; j < result2.rows.length; j++) {
                    if (result2.rows[j].ID_PELICULA == result1.rows[i].ID_PELICULA) {
                        if (images.length > 0) {
                            let isRepeat = false;
                            for (let l = 0; l < images.length; l++) {
                                if (result2.rows[j].ID_FOTOS == images[l]) {
                                    isRepeat = true;
                                }
                            }
                            if (!isRepeat) {
                                images.push(result2.rows[j].ID_FOTOS);
                            }
                        } else {
                            images.push(result2.rows[j].ID_FOTOS);
                        }
                    }
                }
                format.push({
                    Pelicula: movie,
                    Iamgenes: images
                });
                images = [];
            }
            const result = {
                Cantidad: result3.rows,
                Imagenes: format
            }
            res.json(result);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {
        try {
            const img = req.body.IMG;
            const id = req.body.ID;
            if (img && id) {
                //Validaciones para el id de la imagen
                const IDs = await database.simpleExecute(connectionName, `SELECT ID_FOTOS
            FROM IMAGENES`, []);
                let exist = false;
                for (let i = 0; i < IDs.rows.length; i++) {
                    if (IDs.rows[i].ID_FOTOS == id) {
                        exist = true;
                    }
                }
                if (!exist) {
                    res.json('El ID de la imagen no es válido');
                }

                //Validaciones para el documento
                const ext = img.split(".");
                if (ext[1] != "jpg" && ext[1] != "jpeg" && ext[1] != "png") {
                    res.json('LA extensión de la imagen donde se exportará no es válido');
                }

                const procedure =
                    `CREATE OR REPLACE
                PROCEDURE imgExport
                  (
                    source_id CHAR,
                    filename  VARCHAR2
                  )
                AS
                  imgSrc ordsys.ordimage;
                  ctx raw(64) := NULL;
                BEGIN
                  SELECT IMAGE INTO imgSrc FROM Imagenes WHERE Id_Fotos = source_id;
                  imgSrc.export(ctx, 'FILE', 'EXPORTADO', filename);
                END;`;

                const llamada = `BEGIN imgExport('${id}','${img}'); END;`;

                const createProcedure = await database.simpleExecute(connectionName, procedure, []);
                const exportar = await database.simpleExecute(connectionName, llamada, []);
                res.sendStatus(200);
            } else {
                res.json('Faltan componentes necesarios para la descarga');
            }
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    });

router.route('/peliculas/imagenes/:filtro')
    .put(async (req, res) => {

        const filtro = req.params.filtro;
        const id = req.body.ID;
        let procedure, llamada, createProcedure, cambiar;
        if (id) {
            try {
                switch (filtro) {
                    case "blancoYnegro":
                        console.log("Es blanco y negro");
                        procedure = `CREATE OR REPLACE PROCEDURE image_mono(wiCode CHAR)
                        IS
                        img ordsys.ordimage;
                        ctx raw(64) := NULL;
                        BEGIN
                          SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
                          img.process('contentFormat=8bitgray quantize = mediancut 2');
                          UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
                        END;`;
                        llamada = `BEGIN image_mono('${id}'); END;`;
                        createProcedure = await database.simpleExecute(connectionName, procedure, []);
                        cambiar = await database.simpleExecute(connectionName, llamada, []);
                        break;
                    case "rojo":
                        console.log("Es rojo");
                        procedure = `CREATE OR REPLACE PROCEDURE image_red(wiCode CHAR)
                        IS
                        img ordsys.ordimage;
                        ctx raw(64) := NULL;
                        BEGIN
                          SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
                          img.process('contrast="100%" "0%" "0%"');
                          UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
                        END;`;
                        llamada = `BEGIN image_red('${id}'); END;`;
                        createProcedure = await database.simpleExecute(connectionName, procedure, []);
                        cambiar = await database.simpleExecute(connectionName, llamada, []);
                        break;
                    case "azul":
                        console.log("Es azul");
                        procedure = `CREATE OR REPLACE PROCEDURE image_blue(wiCode CHAR)
                        IS
                        img ordsys.ordimage;
                        ctx raw(64) := NULL;
                        BEGIN
                          SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
                          img.process('contrast="0%" "0%" "100%"');
                          UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
                        END;`;
                        llamada = `BEGIN image_blue('${id}'); END;`;
                        createProcedure = await database.simpleExecute(connectionName, procedure, []);
                        cambiar = await database.simpleExecute(connectionName, llamada, []);
                        break;
                    case "verde":
                        console.log("Es verde");
                        procedure = `CREATE OR REPLACE PROCEDURE image_green(wiCode CHAR)
                        IS
                        img ordsys.ordimage;
                        ctx raw(64) := NULL;
                        BEGIN
                          SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
                          img.process('contrast="0%" "100%" "0%"');
                          UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
                        END;`;
                        llamada = `BEGIN image_green('${id}'); END;`;
                        createProcedure = await database.simpleExecute(connectionName, procedure, []);
                        cambiar = await database.simpleExecute(connectionName, llamada, []);
                        break;
                    case "size":
                        console.log("Cambiar tamanio");
                        const width = req.body.WIDTH;
                        const height = req.body.HEIGHT;
                        if (width && height) {
                            procedure = `CREATE OR REPLACE PROCEDURE image_size(wiCode CHAR)
                        IS
                        img ordsys.ordimage;
                        ctx raw(64) := NULL;
                        BEGIN
                          SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
                          img.process('maxScale=${width} ${height}');
                          UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
                        END;`;
                            llamada = `BEGIN image_size('${id}'); END;`;
                            createProcedure = await database.simpleExecute(connectionName, procedure, []);
                            cambiar = await database.simpleExecute(connectionName, llamada, []);
                        } else {
                            console.log("Faltan las dimensiones");
                        }
                        break;
                    default:
                        break;
                }
                res.sendStatus(200);
            } catch (e) {
                console.log(e);
                res.sendStatus(500);
            }
        } else {
            res.json({
                Alerta: "ID faltante",
                Información: "Favor colocar un ID en formato JSON para modificar la imagen correspondiente"
            });
        }
        /*
        const updateSql =
            `UPDATE ARTISTS SET
    ARTIST_NAME = :artist_name,
    GENRE = :genre,
    BIOGRAFY = :biografy
    
    WHERE ARTIST_COD = :artist_cod`;

        const result = await database.simpleExecute(connectionName, updateSql, artist);
*/
        //return result.rows;
        /*const response = {hello: 'This is my API'};*/
        /*
        console.log(result);
        res.json(result);
        */
    });

router.route('/peliculas/audios')
    .get(async (req, res) => {
        const cantidad = `SELECT COUNT(*) as Audios_Disponibles
        FROM AUDIOS`;
        const audios = `SELECT AUDIO_COD, SONG_NAME, ARTIST_NAME
        FROM AUDIOS`;
        try {
            const result1 = await database.simpleExecute(connectionName, cantidad, []);
            const result2 = await database.simpleExecute(connectionName, audios, []);
            const result = {
                Cantidad: result1.rows,
                Audios: result2.rows
            }
            res.json(result);
        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    })
    .post(async (req, res) => {
        try {
            const audio = req.body.AUDIO;
            const id = req.body.ID;
            if (audio && id) {
                //Validaciones para el id de la imagen
                const IDs = await database.simpleExecute(connectionName, `SELECT AUDIO_COD
                FROM AUDIOS`, []);
                let exist = false;
                for (let i = 0; i < IDs.rows.length; i++) {
                    if (IDs.rows[i].AUDIO_COD == id) {
                        exist = true;
                    }
                }
                if (!exist) {
                    res.json('El ID del audio no es válido');
                }

                //Validaciones para el documento
                const ext = audio.split(".");
                if (ext[1] != "mp3" && ext[1] != "mp4" && ext[1] != "mpeg") {
                    res.json('La extensión del audio donde se exportará no es válido');
                }

                const procedure =
                    `CREATE OR REPLACE
                PROCEDURE SONIDO_EXPORT(
                    SOURCE_ID CHAR,
                    FILENAME  VARCHAR2)
                AS
                  AUDSRC ORDSYS.ORDAUDIO;
                  CTX RAW(64) := NULL;
                BEGIN
                  SELECT SONG INTO AUDSRC FROM AUDIOS WHERE AUDIO_COD = SOURCE_ID;
                  AUDSRC.EXPORT(CTX, 'FILE', 'EXPORTADO', FILENAME);
                END;`;

                const llamada = `BEGIN SONIDO_EXPORT('${id}','${audio}'); END;`;

                const createProcedure = await database.simpleExecute(connectionName, procedure, []);
                const exportar = await database.simpleExecute(connectionName, llamada, []);
                res.sendStatus(200);
            } else {
                res.json('Faltan componentes necesarios para la descarga');
            }

        } catch (e) {
            console.log(e);
            res.sendStatus(500);
        }
    });

app.use('/', router);

app.get('/', (req, res) => {
    res.send('Welcome to the Cinema Library!');
});

startup();

async function startup() {
    console.log('Starting application');

    try {
        console.log('Opening connection to databases');

        await database.openConnections();

        console.log('Starting web server');

        app.listen(port, () => {
            console.log('Running on port ' + port);
        });
    } catch (err) {
        console.log('Encountered error', err);

        process.exit(1);
    }

};