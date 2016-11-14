# encoding: utf-8
# Программа "Блокнот"
require 'sqlite3'

# Базовый класс "Запись"
# Задает основные методы и свойства, присущие всем разновидностям Записи
class Post

  @@SQLITE_DB_FILE = 'notepad.sqlite'

  # Набор известных детей класса Запись в виде ассоциативного массива
  def self.post_types
    {'Memo' => Memo, 'Task' => Task, 'Link' => Link}
  end
  # XXX/ Строго говоря этот метод self.types нехорош — родительский класс в идеале в коде
  # не должен никак зависеть от своих конкретных детей. Мы его использовали для простоты
  # (он адекватен поставленной задаче).
  #
  # В сложных приложениях это делается немного иначе: например отдельный класс владеет всей информацией,
  # и умеет создавать нужные объекты (т. н. шаблон проектирования "Фабрика").
  # Или каждый дочерний класс динамически регистрируется в подобном массиве сам во время загрузки программы.
  # См. подробнее книги о паттернах проектирования в доп. материалах.


  # Динамическое создание объекта нужного класса из набора возможных детей
  def self.create(type)
    return post_types[type].new
  end

  # Похожим образом реализован поиск объектов в Ruby on Rails
  def self.find(limit, type, id)

    db = SQLite3::Database.open(@@SQLITE_DB_FILE)

    #  1. конкретная запись
    if !id.nil?
      db.results_as_hash = true

      result = db.execute("SELECT * FROM posts WHERE rowid = ?", id)

      result = result[0] if result.is_a? Array

      db.close

      if result.empty?
        puts "Такой id #{id} не найден в базе"
        return nil
      else
        post = create(result['type'])

        post.load_data(result)

        return post
      end

    else
    #  2. вернуть таблицу записей
      db.results_as_hash = false

      # формируем запрос в базу с нужными условиями
      query = "SELECT rowid, * FROM posts "

      query += "WHERE type = :type " unless type.nil?
      query += "ORDER by rowid DESC "

      query += "LIMIT :limit " unless limit.nil?

      statement = db.prepare(query)

      statement.bind_param('type', type) unless type.nil?
      statement.bind_param('limit', limit) unless limit.nil?

      result = statement.execute!

      statement.close
      db.close

      return result
    end

  end


  # конструктор
  def initialize
    @created_at = Time.now # дата создания записи
    @text = nil # массив строк записи — пока пустой
  end

  # Вызываться в программе когда нужно считать ввод пользователя и записать его в нужные поля объекта
  def read_from_console
    # todo: должен реализовываться детьми, которые знают как именно считывать свои данные из консоли
  end

  # Возвращает состояние объекта в виде массива строк, готовых к записи в файл
  def to_strings
    # todo: должен реализовываться детьми, которые знают как именно хранить себя в файле
  end

  # Записывает текущее состояние объекта в файл
  def save
    file = File.new(file_path, "w:UTF-8") # открываем файл на запись

    for item in to_strings do # идем по массиву строк, полученных из метода to_strings
      file.puts(item)
    end

    file.close # закрываем
  end

  # Метод, возвращающий путь к файлу, куда записывать этот объект
  def file_path
    # Сохраним в переменной current_path место, откуда запустили программу
    current_path = File.dirname(__FILE__)

    # Получим имя файла из даты создания поста метод strftime формирует строку типа "2014-12-27_12-08-31.txt"
    # набор возможных ключей см. в документации Руби
    file_name = @created_at.strftime("#{self.class.name}_%Y-%m-%d_%H-%M-%S.txt")
    # Обратите внимание, мы добавили в название файла даже секунды (%S) — это обеспечит уникальность имени файла

    return current_path + "/" + file_name
  end

  def save_to_db
    db = SQLite3::Database.open(@@SQLITE_DB_FILE)
    db.results_as_hash = true

    db.execute(
        "INSERT INTO posts (" +
          to_db_hash.keys.join(',') +
          ")" +
          " VALUES (" +
            ('?,'*to_db_hash.keys.size).chomp(',') +
          ")",
        to_db_hash.values
    )

    insert_row_id = db.last_insert_row_id

    db.close

    return insert_row_id

  end

  def to_db_hash
   {
     'type' => self.class.name,
     'created_at' => @created_at.to_s
   }
  end

  # получает на вход хэш массив данных и должен заполнить свои поля
  def load_data(data_hash)
    @created_at = Time.parse(data_hash['created_at'])
  end
end

# PS: Весь набор методов, объявленных в родительском классе называется интерфейсом класса
# Дети могут по–разному реализовывать методы, но они должны подчиняться общей идее
# и набору функций, которые заявлены в базовом (родительском классе)

# PPS: в других языках (например Java) методы, объявленные в классе, но пустые
# называются абстрактными (здесь это методы to_strings и read_from_console).
#
# Смысл абстрактных методов в том, что можно писать базовый класс и пользоваться
# этими методами уже как будто они реализованы, не задумываясь о деталях.
# С деталями реализации методов уже заморачиваются дочерние классы.
#