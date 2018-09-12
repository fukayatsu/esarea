gulp        = require 'gulp'
del         = require 'del'
zip         = require 'gulp-zip'
download    = require 'gulp-download'
browserify  = require('browserify')
source      = require('vinyl-source-stream')
uglify      = require('gulp-uglify-es').default

paths =
  lib: 'lib/**/*.*'

gulp.task 'copy', ->
  gulp.src(paths.lib)
    .pipe(gulp.dest('build'))

gulp.task 'coffee', ->
  browserify(
    entries: ["src/js/esarea.coffee"]
    extensions: ['.coffee']
  )
  .transform('coffeeify')
  .bundle()
  .pipe source 'bundle.js'
  .pipe gulp.dest 'build/js'

gulp.task 'compress', (cb) ->
  gulp.src("build/js/bundle.js")
    .pipe(uglify())
    .pipe(gulp.dest("build/js"))

gulp.task 'watch', ->
  gulp.watch paths.lib, gulp.series('copy')
  gulp.watch "src/js/esarea.coffee", gulp.series('coffee', 'compress')

gulp.task 'clean', (cb)->
  del(['build', 'build.zip'], cb);

gulp.task 'zip', ->
  gulp.src('build/**/*.*')
    .pipe(zip('build.zip'))
    .pipe(gulp.dest('./'))

gulp.task 'build',   gulp.series(gulp.parallel('copy', 'coffee'), 'compress')
gulp.task 'rebuild', gulp.series('clean', 'build')
gulp.task 'release', gulp.series('clean', 'build', 'zip')
gulp.task 'default', gulp.series('clean', 'build', 'watch')
