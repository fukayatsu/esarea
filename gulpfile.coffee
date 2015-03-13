gulp        = require 'gulp'
coffee      = require 'gulp-coffee'
del         = require 'del'
zip         = require 'gulp-zip'
runSequence = require 'run-sequence'
download    = require 'gulp-download'

paths =
  lib: 'lib/**/*.*'
  js:  'src/js/**/*.coffee'

gulp.task 'copy', ->
  gulp.src(paths.lib)
    .pipe(gulp.dest('build/'))

gulp.task 'coffee', ->
  gulp.src(paths.js)
    .pipe(coffee())
    .pipe(gulp.dest('build/js/'))

gulp.task 'watch', ->
  gulp.watch paths.lib, ['copy']
  gulp.watch paths.js,  ['coffee']

gulp.task 'clean', (cb)->
  del(['build', 'build.zip'], cb);

gulp.task 'zip', ->
  gulp.src('build/**/*.*')
    .pipe(zip('build.zip'))
    .pipe(gulp.dest('./'))

gulp.task 'build',   ['copy', 'coffee']
gulp.task 'rebuild', -> runSequence('clean', 'build')
gulp.task 'release', -> runSequence('clean', 'build', 'zip')
gulp.task 'default', -> runSequence('clean', 'build', 'watch')
