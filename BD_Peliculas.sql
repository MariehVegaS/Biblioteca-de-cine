SET SERVEROUTPUT ON;
DROP TABLE Foto_Pelicula;
DROP TABLE actor_Pelicula;
DROP TABLE cate_Pelicula;
DROP TABLE BandaSonora_Pelicula;
DROP TABLE Cancion_Banda;
DROP TABLE PELICULAS;
DROP TABLE Director;
DROP TABLE Actores;
DROP TABLE Categorias;
DROP TABLE Imagenes;
DROP TABLE AUDIOS;
--Creacion de la tabla---
CREATE TABLE Director
  (
    ID_Director VARCHAR2(5),
    Nombre      VARCHAR2(35),
    Edad        NUMBER(3,0),
    CONSTRAINT director_pk PRIMARY KEY (ID_Director)
  );
INSERT INTO Director VALUES
  ('D0001', 'Director no especificado', 00
  );
INSERT INTO Director VALUES
  ('D0002', 'Gary Ross',63
  );
INSERT INTO Director VALUES
  ('D0003', 'James Cameron',65
  );
INSERT INTO Director VALUES
  ('D0004', 'Neil Burger', 56
  );
CREATE TABLE Actores
  (
    ID_Actor VARCHAR2(5),
    Nombre   VARCHAR2(35),
    Edad     NUMBER(3,0),
    CONSTRAINT actor_pk PRIMARY KEY (ID_Actor)
  );
INSERT INTO Actores VALUES
  ('A0001', 'Shailene Woodley', 28
  );
INSERT INTO Actores VALUES
  ('A0002', 'Theo James', 34
  );
INSERT INTO Actores VALUES
  ('A0003', 'Ashley Judd', 51
  );
INSERT INTO Actores VALUES
  ('A0004', 'Jai Courtney', 33
  );
INSERT INTO Actores VALUES
  ('A0005', 'Ray Stevenson', 55
  );
INSERT INTO Actores VALUES
  ('A0006', 'Zoë Kravitz', 30
  );
INSERT INTO Actores VALUES
  ('A0007', 'Kate Winslet', 44
  );
/**/
INSERT INTO Actores VALUES
  ('A0008', 'Jennifer Lawrence', 29
  );
INSERT INTO Actores VALUES
  ('A0009', 'Josh Hutcherson', 27
  );
INSERT INTO Actores VALUES
  ('A0010', 'Josh Hutcherson', 27
  );
INSERT INTO Actores VALUES
  ('A0011', 'Liam Hemsworth', 29
  );
INSERT INTO Actores VALUES
  ('A0012', 'Woody Harrelson', 58
  );
INSERT INTO Actores VALUES
  ('A0013', 'Elizabeth Banks', 45
  );
INSERT INTO Actores VALUES
  ('A0014', 'Lenny Kravitz', 55
  );
INSERT INTO Actores VALUES
  ('A0015', 'Donald Sutherland', 84
  );
INSERT INTO Actores VALUES
  ('A0016', 'Sam Worthington', 43
  );
INSERT INTO Actores VALUES
  ('A0017', 'Zoe Saldana', 41
  );
INSERT INTO Actores VALUES
  ('A0018', 'Stephen Lang', 67
  );
INSERT INTO Actores VALUES
  ('A0019', 'Michelle Rodriguez', 41
  );
INSERT INTO Actores VALUES
  ('A0020', 'Sigourney Weaver', 70
  );
CREATE TABLE Categorias
  (
    ID_Categoria VARCHAR2(5),
    descripcion  VARCHAR2(20),
    CONSTRAINT Catego_pk PRIMARY KEY (ID_Categoria)
  );
INSERT INTO Categorias VALUES
  ('C0001', 'Accion'
  );
INSERT INTO Categorias VALUES
  ('C0002', 'Drama'
  );
INSERT INTO Categorias VALUES
  ('C0003', 'Romance'
  );
INSERT INTO Categorias VALUES
  ('C0004', 'Terror'
  );
INSERT INTO Categorias VALUES
  ('C0005', 'Fantasia'
  );
INSERT INTO Categorias VALUES
  ('C0006', 'Misterio'
  );
INSERT INTO Categorias VALUES
  ('C0007', 'Distopicas'
  );
INSERT INTO Categorias VALUES
  ('C0008', 'Animadas'
  );
INSERT INTO Categorias VALUES
  ('C0009', 'Infantiles'
  );
INSERT INTO Categorias VALUES
  ('C0010', 'Policiacas'
  );
INSERT INTO Categorias VALUES
  ('C0011', 'Documentales'
  );
INSERT INTO Categorias VALUES
  ('C0012', 'Ciencia Ficcion'
  );
CREATE TABLE Imagenes
  (
    Id_Fotos VARCHAR2(5),
    IMAGE ordimage NOT NULL,
    CONSTRAINT imagenes_pk PRIMARY KEY (Id_Fotos)
  );
CREATE TABLE AUDIOS
  (
    AUDIO_COD   VARCHAR2(6),
    SONG_NAME   VARCHAR2(50),
    ARTIST_name VARCHAR2(50),
    SONG ORDSYS.ORDAUDIO,
    CONSTRAINT audio_pk PRIMARY KEY (AUDIO_COD)
  );
CREATE TABLE PELICULAS
  (
    id_pelicula VARCHAR(5) NOT NULL,
    titulo      VARCHAR2(30) NOT NULL,
    ID_Director VARCHAR(5) NOT NULL,
    descripcion VARCHAR(600),
    duracion    NUMBER(3,0),
    creditos CLOB,
    guiones ORDDOC,
    CONSTRAINT peli_PK PRIMARY KEY(id_pelicula),
    CONSTRAINT peli_id_direc FOREIGN KEY (ID_Director) REFERENCES Director(ID_Director)
  );
/*PROCEDIMIENTOS PARA IMPORTAR ARCHIVOS(IMAGE, DOCS, AUDIOS)*/
/*IMAGENES*/
CREATE OR REPLACE
PROCEDURE image_import
  (
    wiCode   CHAR,
    filename VARCHAR2
  )
IS
  img ordsys.ordimage;
  ctx raw(64) := NULL;
BEGIN
  SELECT IMAGE INTO img FROM Imagenes WHERE Id_Fotos = wiCode FOR UPDATE;
  img.importfrom(ctx, 'FILE', 'MULTIMEDIA', filename);
  UPDATE Imagenes SET IMAGE = img WHERE Id_Fotos = wiCode;
END;
/
/*DOCS*/
CREATE OR REPLACE
PROCEDURE Insertar_DocsBD(
    vCodigo  CHAR,
    vArchivo VARCHAR2)
IS
  doc ordsys.orddoc;
  ctx raw(64) := NULL;
BEGIN
  SELECT guiones INTO doc FROM PELICULAS WHERE id_pelicula = vCodigo FOR UPDATE;
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
/
/*AUDIOS*/
CREATE OR REPLACE
PROCEDURE Insertar_SonidoBD(
    vAudCod  CHAR,
    vArchivo VARCHAR2)
IS
  aud ordsys.ordaudio;
  ctx raw(64) := NULL;
  --audio_cod number;
BEGIN
  SELECT song INTO aud FROM audios WHERE audio_cod = vAudCod FOR UPDATE;
  aud.importFrom(ctx, 'FILE', 'MULTIMEDIA', vArchivo);
  aud.setProperties(ctx,TRUE);
  --Leyendo propiedades del audio.
  DBMS_OUTPUT.PUT_LINE('Length is: ' || TO_CHAR(aud.getContentLength(ctx)));
  DBMS_OUTPUT.PUT_LINE('Source: ' || aud.getSource());
  DBMS_OUTPUT.PUT_LINE('format: ' || aud.getformat);
  DBMS_OUTPUT.PUT_LINE('encoding: ' || aud.getEncoding);
  DBMS_OUTPUT.PUT_LINE('numberOfChannels: ' || TO_CHAR(aud.getNumberOfChannels));
  DBMS_OUTPUT.PUT_LINE('compressionType : ' || aud.getCompressionType());
  DBMS_OUTPUT.PUT_LINE('samplingRate: ' || TO_CHAR(aud.getSamplingRate));
  DBMS_OUTPUT.PUT_LINE('sampleSize: ' || TO_CHAR(aud.getSampleSize));
  DBMS_OUTPUT.PUT_LINE('audioDuration: ' || TO_CHAR(aud.getAudioDuration()));
  UPDATE AUDIOS SET SONG = aud WHERE AUDIO_COD = vAudCod;
END;
/
/*INSERTAR DATOS Y ARCHIVOS*/
/*IMAGENES*/
INSERT
INTO Imagenes VALUES
  (
    'I0001',
    ordsys.ordimage.init()
  );
CALL image_import('I0001', 'DIVERGENTE_Foto1.jpg');
INSERT INTO Imagenes VALUES
  ('I0002', ordsys.ordimage.init()
  );
CALL image_import('I0002', 'DIVERGENTE_Foto2.jpg');
INSERT INTO Imagenes VALUES
  ('I0003', ordsys.ordimage.init()
  );
CALL image_import('I0003', 'DIVERGENTE_Foto3.jpg');
INSERT INTO Imagenes VALUES
  ('I0004', ordsys.ordimage.init()
  );
CALL image_import('I0004', 'DIVERGENTE_Foto4.jpg');
INSERT INTO Imagenes VALUES
  ('I0005', ordsys.ordimage.init()
  );
CALL image_import('I0005', 'DIVERGENTE_Foto5.jpg');
INSERT INTO Imagenes VALUES
  ('I0006', ordsys.ordimage.init()
  );
CALL image_import('I0006', 'DIVERGENTE_Foto6.jpg');
INSERT INTO Imagenes VALUES
  ('I0007', ordsys.ordimage.init()
  );
CALL image_import('I0007', 'DIVERGENTE_Foto7.jpg');
INSERT INTO Imagenes VALUES
  ('I0008', ordsys.ordimage.init()
  );
CALL image_import('I0008', 'DIVERGENTE_Foto8.jpg');
INSERT INTO Imagenes VALUES
  ('I0009', ordsys.ordimage.init()
  );
CALL image_import('I0009', 'DIVERGENTE_Foto9.jpg');
INSERT INTO Imagenes VALUES
  ('I0010', ordsys.ordimage.init()
  );
CALL image_import('I0010', 'DIVERGENTE_Foto91.jpg');
INSERT INTO Imagenes VALUES
  ('I0011', ordsys.ordimage.init()
  );
CALL image_import('I0011', 'LOSJUEGOSDELHAMBRE_Foto1.jpg');
INSERT INTO Imagenes VALUES
  ('I0012', ordsys.ordimage.init()
  );
CALL image_import('I0012', 'LOSJUEGOSDELHAMBRE_Foto2.jpg');
INSERT INTO Imagenes VALUES
  ('I0013', ordsys.ordimage.init()
  );
CALL image_import('I0013', 'LOSJUEGOSDELHAMBRE_Foto3.jpg');
INSERT INTO Imagenes VALUES
  ('I0014', ordsys.ordimage.init()
  );
CALL image_import('I0014', 'LOSJUEGOSDELHAMBRE_Foto4.jpg');
INSERT INTO Imagenes VALUES
  ('I0015', ordsys.ordimage.init()
  );
CALL image_import('I0015', 'LOSJUEGOSDELHAMBRE_Foto5.jpg');
INSERT INTO Imagenes VALUES
  ('I0016', ordsys.ordimage.init()
  );
CALL image_import('I0016', 'LOSJUEGOSDELHAMBRE_Foto6.jpg');
INSERT INTO Imagenes VALUES
  ('I0017', ordsys.ordimage.init()
  );
CALL image_import('I0017', 'LOSJUEGOSDELHAMBRE_Foto7.jpg');
INSERT INTO Imagenes VALUES
  ('I0018', ordsys.ordimage.init()
  );
CALL image_import('I0018', 'LOSJUEGOSDELHAMBRE_Foto8.jpg');
INSERT INTO Imagenes VALUES
  ('I0019', ordsys.ordimage.init()
  );
CALL image_import('I0019', 'LOSJUEGOSDELHAMBRE_Foto9.jpg');
INSERT INTO Imagenes VALUES
  ('I0020', ordsys.ordimage.init()
  );
CALL image_import('I0020', 'LOSJUEGOSDELHAMBRE_Foto91.jpg');
INSERT INTO Imagenes VALUES
  ('I0021', ordsys.ordimage.init()
  );
CALL image_import('I0021', 'AVATAR_Foto1.jpg');
INSERT INTO Imagenes VALUES
  ('I0022', ordsys.ordimage.init()
  );
CALL image_import('I0022', 'AVATAR_Foto2.jpg');
INSERT INTO Imagenes VALUES
  ('I0023', ordsys.ordimage.init()
  );
CALL image_import('I0023', 'AVATAR_Foto3.jpg');
INSERT INTO Imagenes VALUES
  ('I0024', ordsys.ordimage.init()
  );
CALL image_import('I0024', 'AVATAR_Foto4.jpg');
INSERT INTO Imagenes VALUES
  ('I0025', ordsys.ordimage.init()
  );
CALL image_import('I0025', 'AVATAR_Foto5.jpg');
INSERT INTO Imagenes VALUES
  ('I0026', ordsys.ordimage.init()
  );
CALL image_import('I0026', 'AVATAR_Foto6.jpg');
INSERT INTO Imagenes VALUES
  ('I0027', ordsys.ordimage.init()
  );
CALL image_import('I0027', 'AVATAR_Foto7.jpg');
INSERT INTO Imagenes VALUES
  ('I0028', ordsys.ordimage.init()
  );
CALL image_import('I0028', 'AVATAR_Foto8.jpg');
/*AUDIOS*/
INSERT
INTO AUDIOS VALUES
  (
    'AU0001',
    'Beating Heart',
    'Ellie Goulding',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0001', 'DIVERGENTE_ Beating Heart_Ellie Goulding.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0002',
    'Big Deal',
    'Dream Machines',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0002', 'DIVERGENTE_Big Deal_Dream Machines.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0003',
    'Dead in the water',
    'Ellie Goulding',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0003', 'DIVERGENTE_Dead In the water_Ellie Goulding.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0004',
    'Fight for you',
    'Pia feat Chance the rapper',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0004', 'DIVERGENTE_Fight For You_Pia feat Chance the rapper.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0005',
    'Hanging on i see monsters',
    'Ellie Goulding',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0005', 'DIVERGENTE_Hanging on i see monsters_Ellie Goulding.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0006',
    'I need you',
    'M83',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0006', 'DIVERGENTE_I need you_M83.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0007',
    'I wont let you go',
    'Snow Patrol',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0007', 'DIVERGENTE_I wont let you go_Snow Patrol.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0008',
    'Pretty Lights',
    'Lost and found',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0008', 'DIVERGENTE_Pretty Lights_Lost and found.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0009',
    'Find you',
    'Zedd feat. Matthew Koma y Miriam Bryant',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0009', 'DVERGENTE_Find You_Zedd feat. Matthew Koma y Miriam Bryant.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0010',
    'Atlas',
    'Coldplay',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0010', 'LOSJUEGOSDELHAMBRE_Atlas.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0011',
    'Angel on Fires',
    'Antony and the Johnsons',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0011', 'LOSJUEGOSDELHAMBRE_Angel On Fire.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0012',
    'Lights',
    'Panthogram',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0012', 'LOSJUEGOSDELHAMBRE_Lights.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0013',
    'Place For Us',
    'Mikki Ekko',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0013', 'LOSJUEGOSDELHAMBRE_Place For Us.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0014',
    'Shooting Arrows At The Sky',
    'Santigold',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0014', 'LOSJUEGOSDELHAMBRE_Shooting Arrows At the Sky.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0015',
    'Capitol Letter',
    'Patti Smith',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0015', 'LOSJUEGOSDELHAMBRE_Capitol Letter.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0016',
    'Mirror',
    'Ellie Goulding',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0016', 'LOSJUEGOSDELHAMBRE_Mirror.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0017',
    'Gale',
    'The Lumineers',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0017', 'LOSJUEGOSDELHAMBRE_Gale.m4a');
INSERT
INTO AUDIOS VALUES
  (
    'AU0018',
    'Everybody Wants To Rule the World',
    'Lorde',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0018', 'LOSJUEGOSDELHAMBRE_Everybody Wants To Rule the World.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0019',
    'You dont dream in Cryo',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0019', 'AVATAR_You Dont Dream In Cryo.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0020',
    'Becoming one of the people',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0020', 'AVATAR_Becoming_One_Of_The_People-Becoming_One_With_Neytiri.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0021',
    'Climbing Up Iknimaya',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0021', 'AVATAR_Climbing_Up_Iknimaya_-_The_Path_to_Heaven_.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0022',
    'Jake Enters His Avatar World',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0022', 'AVATAR_Jake Enters His Avatar World.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0023',
    'Jakes First Flight',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0023', 'AVATAR_Jakes_First_Flight_.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0024',
    'Pure Spirits of the Forest',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0024', 'AVATAR_Pure Spirits of the Forest.mp3');
INSERT
INTO AUDIOS VALUES
  (
    'AU0025',
    'The Bioluminescense of the Night',
    'James Horner',
    ordsys.ORDAUDIO.init()
  );
CALL INSERTAR_SONIDOBD('AU0025', 'AVATAR_The_Bioluminescence of the Night_James_Horner.mp3');
/*DOCS*/
INSERT
INTO PELICULAS VALUES
  (
    'P0001',
    'Divergente',
    'D0002',
    'Se desarrolla en el futuro, en una sociedad distópica donde la raza humana está 
dividida en cinco facciones. Cada una de ellas se dedica a cultivar una determinada virtud: Verdad (los sinceros), Abnegación (los altruistas),
Osadía (los valientes), Cordialidad (los pacíficos) y Erudición (los inteligentes). Al cumplir los dieciséis años, Beatrice Prior tiene que 
elegir la facción a la que pertenecerá. Enamorada de un joven, la muchacha se ve obligada a guardar un secreto para evitar que la maten',
    139,
    NULL,
    ORDSYS.ORDDOC()
  );
CALL Insertar_DocsBD('P0001','DIVERGENTE_Guion.docx');
INSERT
INTO PELICULAS VALUES
  (
    'P0002',
    'Los juegos del hambre',
    'D0004',
    'Un pasado de guerras ha dejado los 12 distritos que dividen Panem bajo el 
poder tiránico del "Capitolio". Sin libertad y en la pobreza, nadie puede salir de los límites de su distrito. Sólo una chica de 16 años, Katniss 
Everdeen, osa desafiar las normas para conseguir comida.Cuando su hermana pequeña es elegida para participar, Katniss no duda en ocupar su lugar.',
    142,
    NULL,
    ORDSYS.ORDDOC()
  );
CALL Insertar_DocsBD('P0002','LOSJUEGOSDELHAMBRE_Guion.docx');
INSERT
INTO PELICULAS VALUES
  (
    'P0003',
    'AVATAR',
    'D0003',
    'En un futuro muy lejano, cuando Jake Sully (Sam Worthington) es un veterano de guerra que 
ha quedado parapléjico. Es trasladado en medio de su desesperación a Pandora, una luna del planeta Polifemo habitada por una raza humanoide 
llamada navi, con la que los humanos se encuentran en conflicto por: el unobtainium. Pero Sully no llegará a ese lugar con su identidad original, 
con su propia identidad terrestre, ya que, realmente, han proyectado un avatar del marine que es muy diferente en su aspecto.',
    161,
    NULL,
    ORDSYS.ORDDOC()
  );
CALL Insertar_DocsBD('P0003','AVATAR_Guion.docx');
CREATE TABLE Foto_Pelicula
  (
    Id_Fotos    VARCHAR(6) NOT NULL,
    id_pelicula VARCHAR(5) NOT NULL,
    CONSTRAINT foto_id_pelicula FOREIGN KEY (Id_Fotos) REFERENCES Imagenes(Id_Fotos),
    CONSTRAINT pelicula_id_foto FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula)
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0001', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0002', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0003', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0004', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0005', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0006', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0007', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0008', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0009', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0010', 'P0001'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0011', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0012', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0013', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0014', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0015', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0016', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0017', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0018', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0019', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0020', 'P0002'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0021', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0022', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0023', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0024', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0025', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0026', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0027', 'P0003'
  );
INSERT INTO Foto_Pelicula VALUES
  ('I0028', 'P0003'
  );
CREATE TABLE actor_Pelicula
  (
    ID_Actor    VARCHAR(5) NOT NULL,
    id_pelicula VARCHAR(5) NOT NULL,
    CONSTRAINT actor_id_pelicula FOREIGN KEY (ID_Actor) REFERENCES Actores(ID_Actor),
    CONSTRAINT pelicula_id_actor FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula)
  );
INSERT INTO actor_Pelicula VALUES
  ('A0001', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0002', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0003', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0004', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0005', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0006', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0007', 'P0001'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0008', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0009', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0010', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0011', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0012', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0013', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0014', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0015', 'P0002'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0016', 'P0003'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0017', 'P0003'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0018', 'P0003'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0019', 'P0003'
  );
INSERT INTO actor_Pelicula VALUES
  ('A0020', 'P0003'
  );
CREATE TABLE cate_Pelicula
  (
    ID_Categoria VARCHAR(5) NOT NULL,
    id_pelicula  VARCHAR(5) NOT NULL,
    CONSTRAINT peli_id_categ FOREIGN KEY (ID_Categoria) REFERENCES Categorias(ID_Categoria),
    CONSTRAINT cat_id_pelicula FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula)
  );
INSERT INTO cate_Pelicula VALUES
  ('C0001', 'P0001'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0012', 'P0001'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0007', 'P0002'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0001', 'P0002'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0012', 'P0002'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0001', 'P0003'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0005', 'P0003'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0012', 'P0003'
  );
INSERT INTO cate_Pelicula VALUES
  ('C0008', 'P0003'
  );
CREATE TABLE Cancion_Banda
  (
    id_banda     VARCHAR(5) NOT NULL,
    nombre_banda VARCHAR2(30) NOT NULL,
    CONSTRAINT banda_PK PRIMARY KEY(id_banda)
  );
INSERT INTO Cancion_Banda VALUES
  ('B0001', 'DIVERGENTE SOUNDTRACK'
  );
INSERT INTO Cancion_Banda VALUES
  ('B0002', 'LOSJUEGOSDELHAMBRE SOUNDTRACK'
  );
INSERT INTO Cancion_Banda VALUES
  ('B0003', 'AVATAR SOUNDTRACK'
  );
CREATE TABLE BandaSonora_Pelicula
  (
    id_banda    VARCHAR(5),
    id_pelicula VARCHAR(5),
    AUDIO_COD   VARCHAR2(6),
    CONSTRAINT banda_id_pelicula FOREIGN KEY (id_pelicula) REFERENCES PELICULAS(id_pelicula),
    CONSTRAINT banda_id_cancion_nombre FOREIGN KEY (id_banda) REFERENCES Cancion_Banda(id_banda),
    CONSTRAINT banda_id_cancion FOREIGN KEY (AUDIO_COD) REFERENCES AUDIOS(AUDIO_COD)
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0001'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0002'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0003'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0004'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0005'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0006'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0007'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0008'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0001', 'P0001','AU0009'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0010'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0011'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0012'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0013'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0014'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0015'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0016'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0002', 'P0002','AU0017'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0019'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0020'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0021'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0022'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0023'
  );
INSERT INTO BandaSonora_Pelicula VALUES
  ('B0003', 'P0003','AU0024'
  );
/*PROCEDIMIENTOS PARA EXPORTAR ARCHIVOS(IMAGE, DOCS, AUDIOS)*/
/*IMAGENES*/
CREATE OR REPLACE
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
END;
/
/*AUDIOS*/
CREATE OR REPLACE
PROCEDURE SONIDO_EXPORT(
    SOURCE_ID CHAR,
    FILENAME  VARCHAR2)
AS
  AUDSRC ORDSYS.ORDAUDIO;
  CTX RAW(64) := NULL;
BEGIN
  SELECT SONG INTO AUDSRC FROM AUDIOS WHERE AUDIO_COD = SOURCE_ID;
  AUDSRC.EXPORT(CTX, 'FILE', 'EXPORTADO', FILENAME);
END;
/
/*DOCS*/
CREATE OR REPLACE PROCEDURE doc_export(
    source_id CHAR,
    filename  VARCHAR2)
AS
  docSrc ordsys.orddoc;
  ctx raw(64) := NULL;
BEGIN
  SELECT guiones INTO docSrc FROM PELICULAS WHERE id_pelicula = source_id;
  docSrc.export(ctx, 'FILE', 'EXPORTADO', filename);
END;
/
/*EXPORTAR ARCHIVOS*/
CALL imgExport('I0020','IMAGEN_EXPORTADA.jpg');
CALL SONIDO_EXPORT('AU0020','AUDIO_EXPORTADO.mp3');
CALL doc_export('P0001','afsffas.doc');

SELECT *
FROM peliculas natural join foto_pelicula natural join imagenes;