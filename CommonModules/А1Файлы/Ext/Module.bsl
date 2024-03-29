﻿#Если НЕ Клиент Тогда
	
	Функция Присоединить(ИдентификаторФайла, Знач ИдентификаторВладельца, НаименованиеСРасширением, Замещать = Ложь) Экспорт
		Если ТипЗнч(ИдентификаторФайла) = Тип("ДвоичныеДанные") Тогда
			ДвоичныеДанные = ИдентификаторФайла; 
		ИначеЕсли ТипЗнч(ИдентификаторФайла) = Тип("Строка") Тогда //Это адрес во временном хранилище.
			ДвоичныеДанные = ПолучитьИзВременногоХранилища(ИдентификаторФайла);
		Иначе
			А1Э_Служебный.СлужебноеИсключение("Неверный тип аргумента!");
		КонецЕсли;
		ИдентификаторВладельца = А1Э_Метаданные.ИдентификаторПоСсылке(ИдентификаторВладельца);
		ЧастиИмени = А1Э_Строки.ПередПослеСКонца(НаименованиеСРасширением, ".");
		Наименование = ЧастиИмени.Перед;
		Расширение = ЧастиИмени.После;
		Хэш = А1Э_Файлы.Хэш(ДвоичныеДанные);
		НачатьТранзакцию();
		Если Замещать Тогда
			СуществующийФайл = НайтиПоНаименованию(Наименование, ИдентификаторВладельца);
			Если СуществующийФайл <> Неопределено Тогда 
				ФайлОбъект = СуществующийФайл.ПолучитьОбъект();
			КонецЕсли;		
		КонецЕсли;
		//Известный баг - если файл, существующий в системе с одним наименованием, присоединить к другому объекту с другим наименованием в режиме замещения, ничего не получится.
		ФайлСсылка = Справочники.А1Файлы.НайтиПоРеквизиту("Хэш", Хэш);
		Если ЗначениеЗаполнено(ФайлСсылка) Тогда
			Сообщить("Был присоединен существующий в системе файл. Наименование может отличаться!");
		Иначе	
			Если ФайлОбъект = Неопределено Тогда
				ФайлОбъект = Справочники.А1Файлы.СоздатьЭлемент();
			КонецЕсли;
			ФайлОбъект.Наименование = Наименование;
			ФайлОбъект.Расширение = Расширение;
			Если НЕ ЗначениеЗаполнено(ФайлОбъект.Ссылка) Тогда //Переопределяем том только для новых файлов, при замещении том остается как был.
				ФайлОбъект.Том = А1Э_НастройкиСистемы.Значение("А1Файлы", "ТомПоУмолчанию");
			КонецЕсли;
			ФайлОбъект.Размер = ДвоичныеДанные.Размер();
			ФайлОбъект.Хэш = А1Э_Файлы.Хэш(ДвоичныеДанные);
			ФайлОбъект.Записать();
			ФайлСсылка = ФайлОбъект.Ссылка;
			Если ЗначениеЗаполнено(ФайлОбъект.Том) Тогда
				ДвоичныеДанные.Записать(А1Э_Файлы.СложитьПути(ФайлСсылка.Том.Путь, ФайлСсылка.УникальныйИдентификатор()));
			Иначе
				Менеджер = РегистрыСведений.А1Файлы_ХранилищеФайлов.СоздатьМенеджерЗаписи();
				Менеджер.Файл = ФайлСсылка;
				Менеджер.Хранилище = Новый ХранилищеЗначения(ДвоичныеДанные);
				Менеджер.Записать();
			КонецЕсли;
		КонецЕсли;
		
		Менеджер = РегистрыСведений.А1Файлы_ПрисоединенныеФайлы.СоздатьМенеджерЗаписи();
		Менеджер.Объект = ИдентификаторВладельца;
		Менеджер.Файл = ФайлСсылка;
		Менеджер.Записать(Истина);
		ЗафиксироватьТранзакцию();
	КонецФункции 
	
	Функция Отсоединить(ФайлСсылка, Знач ИдентификаторВладельца) Экспорт
		ИдентификаторВладельца = А1Э_Метаданные.ИдентификаторПоСсылке(ИдентификаторВладельца);
		Менеджер = РегистрыСведений.А1Файлы_ПрисоединенныеФайлы.СоздатьМенеджерЗаписи();
		Менеджер.Объект = ИдентификаторВладельца;
		Менеджер.Файл = ФайлСсылка;
		Менеджер.Удалить();
	КонецФункции
	
	Функция НайтиПоНаименованию(Наименование, Владелец = Неопределено) Экспорт
		Запрос = Новый Запрос;
		Если Владелец = Неопределено Тогда
			Запрос.Текст = 
			"ВЫБРАТЬ
			|	Файлы.Ссылка КАК Ссылка
			|ИЗ
			|	Справочник.А1Файлы КАК Файлы
			|ГДЕ
			|	Файлы.Наименование = &Наименование";
		Иначе
			Запрос.Текст = 
			"ВЫБРАТЬ
			|	Файлы.Файл КАК Ссылка
			|ИЗ
			|	РегистрСведений.А1Файлы_ПрисоединенныеФайлы КАК Файлы
			|ГДЕ
			|	Файлы.Объект = &Владелец
			|	И Файлы.Файл.Наименование = &Наименование";
			Запрос.УстановитьПараметр("Владелец", А1Э_Метаданные.ИдентификаторПоСсылке(Владелец));
		КонецЕсли;
		Запрос.УстановитьПараметр("Наименование", Наименование);
		Выборка = Запрос.Выполнить().Выбрать();
		Если НЕ Выборка.Следующий() Тогда Возврат Неопределено; КонецЕсли;
		Возврат Выборка.Ссылка;
	КонецФункции
	
	Функция ДвоичныеДанные(ФайлСсылка) Экспорт
		Если ЗначениеЗаполнено(ФайлСсылка.Том) Тогда
			Возврат Новый ДвоичныеДанные(А1Э_Файлы.СложитьПути(ФайлСсылка.Том.Путь, ФайлСсылка.УникальныйИдентификатор()));
		Иначе
			Менеджер = РегистрыСведений.А1Файлы_ХранилищеФайлов.СоздатьМенеджерЗаписи();
			Менеджер.Файл = ФайлСсылка;
			Менеджер.Прочитать();
			Если НЕ Менеджер.Выбран() Тогда
				А1Э_Служебный.СлужебноеИсключение("Файл отсутствует в хранилище файлов!");
			КонецЕсли;
			Возврат Менеджер.Хранилище.Получить();
		КонецЕсли; 
	КонецФункции
	
	Функция ДвоичныеДанныеПоНаименованию(Наименование, Владелец = Неопределено) Экспорт 
		ФайлСсылка = НайтиПоНаименованию(Наименование, Владелец);
		Если ФайлСсылка = Неопределено Тогда Возврат Неопределено; КонецЕсли;
		
		Возврат ДвоичныеДанные(ФайлСсылка);
	КонецФункции
	
	Функция ПоместитьВХранилище(ФайлСсылка, АдресДляПомещения) Экспорт
		Возврат ПоместитьВоВременноеХранилище(ДвоичныеДанные(ФайлСсылка), АдресДляПомещения);
	КонецФункции
	
#КонецЕсли
 
#Область Механизм

Функция НастройкиМеханизма() Экспорт
	Настройки = А1Э_Механизмы.НовыйНастройкиМеханизма();
	
	Настройки.Обработчики.Вставить("ФормаЭлементаПриСозданииНаСервере", Истина);
	
	Настройки.ПорядокВыполнения = 10000;
	
	Возврат Настройки;
КонецФункции  

#Если НЕ Клиент Тогда
	
	Функция ФормаЭлементаПриСозданииНаСервере(Форма, Отказ, СтандартнаяОбработка) Экспорт
		МассивОписаний = Новый Массив;
		А1Э_Формы.ДобавитьОписаниеГруппы(МассивОписаний, "А1Файлы_Группа", "Файлы", Форма.КоманднаяПанель);
		ДобавитьОписаниеКнопкиПрисоединить(МассивОписаний, , Форма.Объект.Ссылка, , , "А1Файлы_Группа");
		А1Э_Формы.ДобавитьОписаниеКомандыИКнопки(МассивОписаний, "А1Файлы_ПоказатьСписок", ИмяМодуля() + ".КомандаПоказатьСписок", , "Показать список", "А1Файлы_Группа");
		А1Э_УниверсальнаяФорма.ДобавитьРеквизитыИЭлементы(Форма, МассивОписаний);
	КонецФункции
	
#КонецЕсли
  
#КонецОбласти

#Область КнопкаПрисоединить

Функция ДобавитьОписаниеКнопкиПрисоединить(МассивОписаний, ИмяКомпонента = "А1Файлы_Присоединить", Владелец, Знач Действие = Неопределено, Заголовок = "Добавить", РодительЭлемента = Неопределено, ПередЭлементом = Неопределено, Параметры = Неопределено, Действия = Неопределено) Экспорт
	Если НЕ А1Э_Доступы.ЕстьПраво("Изменение", "Справочник.А1Файлы") Тогда Возврат Неопределено; КонецЕсли;
	
	РабочиеПараметры = А1Э_Структуры.СкопироватьВШаблон(Параметры,
	"Картинка", БиблиотекаКартинок.СоздатьЭлементСписка,
	"Отображение", ОтображениеКнопки.КартинкаИТекст,
	);
	А1Э_УниверсальнаяФорма.ДобавитьОписаниеНастроекКомпонента(МассивОписаний, ИмяКомпонента, А1Э_Структуры.Создать(
	"Владелец", Владелец,
	));

	
	РабочиеДействия = А1Э_Структуры.Скопировать(Действия);
	А1Э_УниверсальнаяФорма.ДобавитьОбработчикКДействиям(РабочиеДействия, "ФормаПриЗаписиНаСервере", ИмяМодуля() + ".КомандаПрисоединитьФормаПриЗаписиНаСервере:НаСервере");
	РабочееДействие = А1Э_Массивы.Массив(Действие);
	РабочееДействие.Вставить(0, ИмяМодуля() + ".КомандаПрисоединить:НаКлиентеАсинхронно");
	А1Э_Формы.ДобавитьОписаниеКомандыИКнопки2(МассивОписаний, ИмяКомпонента, РабочееДействие, Заголовок, РодительЭлемента, ПередЭлементом, Параметры, РабочиеДействия);
КонецФункции

#Если Клиент Тогда
	
	Функция КомандаПрисоединить(АсинхронныйКонтекст, Форма, Команда) Экспорт 
		АсинхронныйКонтейнер = А1Э_УниверсальнаяФорма.АсинхронныйКонтейнер(АсинхронныйКонтекст, Форма, Команда);
		Настройки = А1Э_УниверсальнаяФорма.НастройкиКомпонента(Форма, Команда.Имя);
		Если НЕ ЗначениеЗаполнено(Настройки.Владелец) Тогда
			Сообщить("Для присоединения файла объект необходимо записать.");
			А1Э_УниверсальнаяФорма.ЗавершитьАсинхронныйОбработчик(АсинхронныйКонтейнер);
			Возврат Неопределено;
		КонецЕсли;
		
		Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
		НачатьПомещениеФайла(Новый ОписаниеОповещения("КомандаПрисоединитьПослеВыбора", ЭтотОбъект, А1Э_Структуры.Создать(
		"Форма", Форма,
		"АсинхронныйКонтейнер", АсинхронныйКонтейнер,
		"Владелец", Настройки.Владелец,
		"Наименование", А1Э_Общее.ЗначениеСвойства(Настройки, "Наименование"),
		)), , , Истина, Форма.УникальныйИдентификатор);
	КонецФункции
	
	Функция КомандаПрисоединитьПослеВыбора(Результат, Адрес, ПутьКФайлу, Контекст) Экспорт
		Если Результат = Ложь Тогда Возврат Неопределено; КонецЕсли;
		
		РабочееНаименование = ?(Контекст.Наименование = Неопределено, А1Э_Строки.ПослеСКонца(ПутьКФайлу, "\"), Контекст.Наименование);
		А1Э_ОбщееСервер.РезультатФункции(ИмяМодуля() + ".Присоединить", Адрес, Контекст.Владелец, РабочееНаименование, ЗначениеЗаполнено(Контекст.Наименование));
		А1Э_УниверсальнаяФорма.ЗавершитьАсинхронныйОбработчик(Контекст.АсинхронныйКонтейнер);
	КонецФункции

#КонецЕсли
#Если НЕ Клиент Тогда
	
	Функция КомандаПрисоединитьФормаПриЗаписиНаСервере(ИмяКомпонента, Форма, Отказ, ТекущийОбъект, ПараметрыЗаписи) Экспорт
		Настройки = А1Э_УниверсальнаяФорма.НастройкиКомпонента(Форма, ИмяКомпонента);
		Если НЕ ЗначениеЗаполнено(Настройки.Владелец) Тогда
			Настройки.Владелец = Форма.Объект.Ссылка;
		КонецЕсли;
	КонецФункции 
#КонецЕсли
 
#КонецОбласти

#Область КнопкаПрисоединитьФиксированный

Функция ДобавитьОписаниеКнопкиПрисоединитьФиксированный(МассивОписаний, ИмяКомпонента, НаименованиеФайла, Владелец, Знач Действие = Неопределено, Заголовок = Неопределено, РодительЭлемента = Неопределено, ПередЭлементом = Неопределено, Параметры = Неопределено, Действия = Неопределено) Экспорт   
	Если НЕ А1Э_Доступы.ЕстьПраво("Изменение", "Справочник.А1Файлы") Тогда Возврат Неопределено; КонецЕсли;
	
	А1Э_УниверсальнаяФорма.ДобавитьОписаниеНастроекКомпонента(МассивОписаний, ИмяКомпонента, А1Э_Структуры.Создать(
	"Владелец", Владелец,
	"Наименование", НаименованиеФайла,
	));

	РабочиеДействия = А1Э_Структуры.Скопировать(Действия);
	А1Э_УниверсальнаяФорма.ДобавитьОбработчикКДействиям(РабочиеДействия, "ФормаПриЗаписиНаСервере", ИмяМодуля() + ".КомандаПрисоединитьФормаПриЗаписиНаСервере:НаСервере");
	РабочееДействие = А1Э_Массивы.Массив(Действие);
	РабочееДействие.Вставить(0, ИмяМодуля() + ".КомандаПрисоединить:НаКлиентеАсинхронно");
	А1Э_Формы.ДобавитьОписаниеКомандыИКнопки2(МассивОписаний, ИмяКомпонента, РабочееДействие, Заголовок, РодительЭлемента, ПередЭлементом, Параметры, РабочиеДействия);
КонецФункции

#КонецОбласти

#Область КнопкаПоказатьСписок

Функция ДобавитьОписаниеКнопкиПоказатьСписок(МассивОписаний, ИмяКомпонента = "А1Файлы_ПоказатьСписок", Заголовок = "Показать список", РодительЭлемента = Неопределено, ПередЭлементом = Неопределено, Параметры = Неопределено, Действия = Неопределено) Экспорт
		
КонецФункции

#Если Клиент Тогда
	
	Функция КомандаПоказатьСписок(Форма, Команда) Экспорт
		Если НЕ ЗначениеЗаполнено(Форма.Объект.Ссылка) Тогда
			Сообщить("Для просмотра списка присоединенных файлов объект необходимо записать.");
			Возврат Неопределено;
		КонецЕсли;
		А1Файлы_Форма.Открыть(Форма.Объект.Ссылка);
	КонецФункции 
	
#КонецЕсли

#КонецОбласти 

#Область Импорт

Функция А1БК_ПолеВыбораФайла() Экспорт
	Возврат Модуль("А1БК_ПолеВыбораФайла");
КонецФункции

Функция Модуль(Имя)
	Возврат Вычислить(Имя);
КонецФункции

#КонецОбласти

Функция ИмяМодуля() Экспорт
	Возврат "А1Файлы";	
КонецФункции 