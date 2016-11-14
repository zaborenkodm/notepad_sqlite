# encoding: utf-8
# Программа "Блокнот", демонстрирующая как эффективно наследовать классы в ruby

# XXX/ Этот код необходим только при использовании русских букв на Windows
if (Gem.win_platform?)
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__

  [STDIN, STDOUT].each do |io|
    io.set_encoding(Encoding.default_external, Encoding.default_internal)
  end
end
# /XXX

# Подключаем класс Post и его детей
require_relative 'post.rb'
require_relative 'memo.rb'
require_relative 'link.rb'
require_relative 'task.rb'

# Как обычно, при использовании классов программа выглядит очень лаконично
puts "Привет, я твой блокнот! Версия 2 + SQLite"

# Теперь надо спросить у пользователя, что он хочет создать
puts "Что хотите записать в блокнот?"

# массив возможных видов Записи (поста)
choices = Post.post_types.keys

choice = -1

until choice >= 0 && choice < choices.size # пока юзер не выбрал правильно
  # выводим заново массив возможных типов поста
  choices.each_with_index do |type, index|
    puts "\t#{index}. #{type}"
  end
  choice = gets.chomp.to_i
end

# выбор сделан, создаем запись с помощью стат. метода класса Post
entry = Post.create(choices[choice])

# сейчас в переменной entry лежит один из детей класса Post, какой именно,
# определилось выбором пользователя, переменной choice.
# Но мы не знаем какой, и обращаемся с entry как с объектом класса Post, этого оказывается достаточно.

# Просим пользователя ввести пост (каким бы он ни был)
entry.read_from_console

# Сохраняем пост в файл
id = entry.save_to_db

puts "Ваша запись сохранена, id = #{id}"
