npm run start & background_pid=$!

# Run the tests
npm run test:run
return_value=$?

kill -SIGTERM $background_pid

exit $return_value
