times = []
sum = 0
avg = 0
while true
  input = gets
  if input.nil?
    break
  else
    time = input.chomp
    times << time.split('=')[1].chop.chop.to_i
  end
end
times.each do |n|
  sum += n
end
avg = sum / times.count
puts "The average time to serve a page is: #{avg} ms"
