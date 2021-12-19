<template>
<div class="m-3 m-md-5" ref="container">
  <h1 class="my-5">Happy Christmas, Mom!</h1>

  <h3 class="text-left">Select an image to match to DMC embroidery floss colors</h3>

  <!-- select file & match button -->
  <div id="input-opts" class="d-flex flex-wrap mb-3 align-items-start justify-content-between">
    <!-- select file -->
    <div class="d-flex align-items-center">
      <div class="d-flex flex-column align-items-start my-2">
        <h5 class="primary-color font-weight-bold m-0">1 Select file</h5>
        <b-form-file type="file" id="file" accept="image/*" @change="loadFile" />
      </div>

      <!-- loading icon -->
      <button class="btn btn-info text-light ml-4 mt-4" type="button" disabled v-if="isLoading">
        <span class="spinner-grow spinner-grow-sm" role="status" aria-hidden="true"></span>
        Loading...
      </button>
    </div>

    <!-- averaging -->
    <div class="d-flex flex-column align-items-start my-2" v-if="fileLoaded && !isLoading">
      <h5 class="primary-color font-weight-bold m-0  mb-2">2 Adjust simplification</h5>
      <div class="d-flex align-items-start">
        <!-- <b-button @click="matchColors" class="btn-outline-secondary mr-3" :class="{'disabled': isMatching}">crop</b-button> -->

        <!-- change amount of averaging -->
        <div id="input-degree-avg mr-5 d-flex align-items-center">
          <label for="num-colors" class="d-flex justify-content-between mr-2 mb-n2">
            Amount of simplification
          </label>

          <b-form-input id="num-colors-range" v-model="numColors2Match" type="range" min="1" max="512" step="1" @change="debounceSimplifyImage()"></b-form-input>
          <div class="d-flex justify-content-between mt-n3">
            <span>more</span>
            <span>less</span>
          </div>

          <div class="d-flex flex-column mt-2">
            <span class="d-flex">
              <b-form-input id="num-colors" style="width: 75px" v-model="numColors2Match" type="number" min="1" max="512" step="1" @change="debounceSimplifyImage()"></b-form-input>
              <span class="ml-3">colors to match</span>
            </span>
            Est. time: ~ {{estimatedTime}}
          </div>
        </div>

      </div>
    </div>

    <!-- match button w/ progress bar -->
    <div v-if="fileLoaded && !isLoading" class="d-flex flex-column align-items-start my-2">
      <h5 class="primary-color font-weight-bold m-0  mb-2">3 Match colors</h5>
      <div class="d-flex flex-wrap">
        <!-- execute -->
        <b-button @click="matchColors" class="btn btn-info btn-lg" :class="{'disabled': isMatching}">Match</b-button>

        <!-- Progress bar -->
        <div class="ml-3 w-400px">
          <div class="d-flex flex-column arrange-items-center">
            <small class="text-muted">Percent matched</small>
            <b-progress max="1" height="1.25rem" show-progress variant="info" :animated="matchProgress < 1">
              <b-progress-bar :value="matchProgress" :label="`${(matchProgress * 100).toFixed(1)}%`" key="pb"></b-progress-bar>
            </b-progress>
          </div>
        </div>
      </div>
    </div>

  </div>



  <!-- image previews -->
  <div id="image-previews" :class="[fileLoaded ? 'd-flex flex-column' : 'd-none' ]">
    <h3>Previews</h3>
    <div class="d-flex flex-wrap">

      <div id="original-preview">
        <h5>original image</h5>
        <canvas id="canvas"></canvas>
      </div>

      <div id="average-preview" class="ml-2" :class="[isLoading ? 'd-none' : 'd-flex flex-column' ]">
        <h5>simplified image</h5>
        <canvas id="preview"></canvas>

        <!-- change amount of averaging -->
        <div id="input-degree-avg mr-5 d-flex align-items-center">
          <label for="num-colors" class="d-flex justify-content-between mr-2 mb-n2">
            Amount of simplification
          </label>

          <b-form-input id="num-colors-range" v-model="numColors2Match" type="range" min="1" max="512" step="1" @change="debounceSimplifyImage()"></b-form-input>
          <div class="d-flex justify-content-between mt-n3">
            <span>more</span>
            <span>less</span>
          </div>

          <div class="d-flex flex-column mt-2">
            <span class="d-flex">
              <b-form-input id="num-colors" style="width: 75px" v-model="numColors2Match" type="number" min="1" max="512" step="1" @change="debounceSimplifyImage()"></b-form-input>
              <span class="ml-3">colors to match</span>
            </span>
            Est. time: ~ {{estimatedTime}}
          </div>
        </div>

      </div>
    </div>
  </div>


  <!-- results -->
  <div id="results" class="border-top mt-4 pt-4 ">
    <div class="d-flex align-items-center mb-4" v-if="matchedColors.length">
      <div class="d-flex flex-column align-items-start">
        <h2>Matched colors</h2>
        <a href="#matched-table">
          view table
        </a>
      </div>

      <!-- number of colors -->
      <!-- <div class="ml-5 d-flex justify-content-end">
        <div id="input-num-colors mr-5 text-left d-flex w-25">
          <label for="num-colors" class="flex-shrink-0 mr-2 m-0">Number of colors</label>
          <b-form-input id="num-colors" v-model="numMatches" type="number" min="1" placeholder="Number of colors"></b-form-input>
        </div>
      </div> -->
    </div>

    <!-- Result preview -->
    <div id="result-preview">
      <b-form-checkbox-group id="checkbox-group" v-model="selectedIDs" name="selectedIDs" class="d-flex flex-wrap" @change="debounceMaskResults">
        <b-form-checkbox v-for="(color, idx) in matchedColors" :value="color.dmc_id" class="fa-sm">
          <span :style="{ color: color.dmc_hex, background: color.dmc_hex}" class="">&nbsp;&nbsp;&nbsp;&nbsp;</span>
          {{color.dmc_name}} ({{color.dmc_id}})
        </b-form-checkbox>
      </b-form-checkbox-group>
    </div>

    <canvas id="result" :class="[matchedColors.length ? 'd-flex flex-column' : 'd-none' ]"></canvas>

    <!-- <div class="d-flex flex-wrap" id="preview-results">
      <div v-for="(result, rIdx) in numMatches" :key=rIdx class="m-2" :class="[matches2Preview.length ? 'd-flex flex-column align-items-start' : 'd-none' ]">
        <div class="d-flex" v-if="matches2Preview.length && matches2Preview[rIdx]">
          <div :style="{width: '50px', height: '25px', background: matches2Preview[rIdx].dmc_hex}">
          </div>
          <h4 class="m-0 ml-2"><span class="font-weight-bold">DMC {{matches2Preview[rIdx]["dmc_id"]}}</span> {{matches2Preview[rIdx]["dmc_name"]}}</h4>
        </div>
        <canvas :id="'result' + rIdx"></canvas>
      </div>
    </div> -->

    <template v-if="matchedColors.length">
      <table id="matched-table">
        <thead>
          <tr class="font-weight-bold text-left">
            <td>

            </td>
            <td>
              DMC code
            </td>
            <td>
              name
            </td>
            <td>
              Percent of image
            </td>
            <td>
              Avg. score (lower is a closer match)
            </td>
          </tr>
        </thead>

        <tbody>
          <tr v-for="(color, idx) in matchedColors" :key="idx" class="text-left">
            <td :style="{width: '50px', height: '25px', background: color.dmc_hex, border: '4px solid white'}">
            </td>
            <td class="h4">
              {{color.dmc_id}}
            </td>
            <td>
              {{color.dmc_name}}
            </td>
            <td>
              {{color.pct}}
            </td>
            <td>
              {{color.score}}
            </td>
          </tr>
        </tbody>

      </table>
    </template>

  </div>

</div>
</template>

<script>
import {
  deltaE
} from "chroma-js";
import chroma from 'chroma-js';
// import DMC from "@/assets/dmc_colors.json";
import DMC from "@/assets/dmc_colors_ldh.json";
import chunk from "lodash/chunk";
import sumBy from "lodash/sumBy";
import countBy from "lodash/countBy";
import groupBy from "lodash/groupBy";
import * as _ from "lodash";
import * as d3 from "d3-format";
import * as RgbQuant from "rgbquant"; // https://www.npmjs.com/package/rgbquant

export default {
  name: 'ImportPic',
  data() {
    return {
      // constants / placeholders for sizing / calc values
      imageWidth: 80,
      imageHeight: 80,
      maxScreenWidth: 80,
      colorsPerSec: 200,

      // inputs
      initialNum2Match: 50,
      numColors2Match: null, // holder for input manipulations
      numMatches: 10,

      // progress / status
      matchProgress: 0,
      isLoading: false,
      isMatching: false,
      fileLoaded: false,

      // refs
      originalCanvas: null,
      resultCtx: null,
      timer: null,

      // images
      simplifiedImagePixels: [],
      simplifiedColorArr: [],
      matchedColors: [],
      matchedPixelArr: [],
      matches2Preview: [],
      selectedIDs: []
    }
  },
  computed: {
    estimatedTime() {
      const est = this.numColors2Match / this.colorsPerSec;
      if (est < 0.05) {
        return ("< 0.1 seconds")
      } else if (est < 60) {
        return (`${d3.format("0.1f")(est)} seconds`)
      } else if (est < 3600) {
        return (`${d3.format("0.1f")(est/60)} minutes`)
      } else {
        return (`${d3.format("0.1f")(est/3600)} hours`)
      }
    }
  },
  created: function() {
    this.debounceSimplifyImage = _.debounce(this.simplifyImage, 250);
    this.debounceMaskResults = _.debounce(this.plotResults, 250);
  },
  mounted() {
    this.numColors2Match = this.initialNum2Match;
    this.maxScreenWidth = this.$refs.container.clientWidth;
    DMC.forEach(d => {
      d["color"] = chroma(d.hex);
      d["rgb"] = d.color.rgb();
      d["hsv"] = d.color.hsv();
    })
  },
  beforeDestroy() {
    clearTimeout(this.timer);
  },
  methods: {
    loadFile(event) {
      this.isLoading = true;

      // resetting the values on new file load.
      this.isMatching = false;
      this.matchProgress = 0;
      this.matchedColors = [];
      this.fileLoaded = false;
      this.numColors2Match = this.initialNum2Match;

      this.originalCanvas = document.getElementById('canvas'); // load context of canvas
      var ctx = this.originalCanvas.getContext('2d'); // load context of canvas
      var img = new Image();
      img.src = URL.createObjectURL(event.target.files[0]); // use first selected image from input element

      img.onload = (e) => {
        // resize to the screen
        if (this.maxScreenWidth > 500) {
          this.imageWidth = this.maxScreenWidth * 0.45;
          this.imageHeight = this.imageWidth * (img.height / img.width);
        } else {
          this.imageWidth = this.maxScreenWidth * 0.95;
          this.imageHeight = this.imageWidth * (img.height / img.width);
        }

        // resize canvas to image
        this.originalCanvas.width = this.imageWidth;
        this.originalCanvas.height = this.imageHeight;

        ctx.drawImage(img, 0, 0, this.imageWidth, this.imageHeight); // draw the image to the canvas

        this.simplifyImage();

        // allow color matching to happen
        this.fileLoaded = true;
      }
    },
    calcDist(color) {
      DMC.forEach(d => {
        d.dist = deltaE(color, d.color);
      })

      DMC.sort((a, b) => a.dist - b.dist);

      const closestColor = DMC[0];
      return (closestColor)
    },
    simplifyImage() {
      this.isLoading = true;
      this.isMatching = false;
      this.timer = setTimeout(() => {

        let q = new RgbQuant({
          colors: this.numColors2Match
        });
        q.sample(this.originalCanvas);
        let simplifiedImage = q.reduce(this.originalCanvas);

        // plot rounded version
        var canvas = document.getElementById('preview'); // load context of canvas

        canvas.width = this.imageWidth;
        canvas.height = this.imageHeight;

        var ctx = canvas.getContext('2d'); // load context of canvas

        var palette = new ImageData(new Uint8ClampedArray(simplifiedImage), this.imageWidth, this.imageHeight)
        ctx.putImageData(palette, 0, 0);


        const simplifiedChunks = chunk(simplifiedImage, 4);

        this.simplifiedImagePixels = simplifiedChunks.map((d, i) => {
          return ({
            idx: i,
            rgba: d
          })
        })

        // count the number of occurrences of RGBA values, to reduce to single values to compare.
        this.simplifiedColorArr = _(this.simplifiedImagePixels).groupBy("rgba")
          .map((values, key) => ({
            idx: values.map(d => d.idx),
            count: values.length,
            id: key
          }))
          .value()

        // sort high to low
        this.simplifiedColorArr.sort((a, b) => b.count - a.count);

        this.isLoading = false;
      }, 1000)
    },
    calcMatch(d, i) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          this.matchProgress = (i + 1) / this.simplifiedColorArr.length;
          let obj = {};
          const rgba = d.id.split(",")
          obj["color"] = chroma(`rgba(${rgba[0]}, ${rgba[1]}, ${rgba[2]}, ${rgba[3]/255})`);
          const closest = this.calcDist(obj.color);
          obj["hex"] = obj.color.hex();
          obj["idx"] = d.idx;
          obj["pixel_count"] = d.count;
          obj["closest_hex"] = closest.hex;
          obj["closest_rgb"] = closest.rgb;
          obj["closest_hsv"] = closest.hsv;
          obj["closest_name"] = closest.name;
          obj["closest_dmc_id"] = closest.dmc_id;
          obj["closest_score"] = closest.dist;
          resolve(obj)
        }, 100)
      });
    },
    matchColors() {
      this.isMatching = true;

      Promise.all(this.simplifiedColorArr.map((d, i) => this.calcMatch(d, i))).then((matchedColorArr) => {
        // sum number of occurrences of the DMC color
        this.matchedColors = _(matchedColorArr).groupBy("closest_dmc_id")
          .map((values, i) => ({
            values: values,
            dmc_id: values[0]["closest_dmc_id"],
            dmc_name: values[0]["closest_name"],
            dmc_hex: values[0]["closest_hex"],
            dmc_rgb: values[0]["closest_rgb"],
            dmc_hue: Math.round(values[0]["closest_hsv"][0] / 10),
            dmc_saturation: Math.round(values[0]["closest_hsv"][1] * 10),
            idx: values.flatMap(d => d.idx),
            count: sumBy(values, "pixel_count"),
            score: d3.format("0.2f")(_.meanBy(values, "closest_score")),
            pct: d3.format("0.1%")(sumBy(values, "pixel_count") / this.simplifiedImagePixels.length)
          }))
          .value();

        // // pull out matches to preview
        // this.matchedColors.sort((a, b) => b.count - a.count);
        // this.matches2Preview = this.matchedColors.slice(0, this.numMatches);
        //
        // // plot the small multiples preview
        // this.matches2Preview.map((color, idx) => this.plotResult(color, idx));

        // sort descendingly by count
        this.matchedColors.sort((a, b) => b.dmc_hue - a.dmc_hue || a.dmc_saturation - b.dmc_saturation);

        // plot the results
        this.selectedIDs = this.matchedColors.map(d => d.dmc_id);
        this.plotResults();
      });
    },
    plotResults() {
      let pixels = new Array(this.simplifiedImagePixels.length * 4).fill(0);

      this.matchedColors.filter(d => this.selectedIDs.includes(d.dmc_id)).forEach(color => {
        color.idx.forEach(i => {
          pixels[+i * 4] = color.dmc_rgb[0];
          pixels[+i * 4 + 1] = color.dmc_rgb[1];
          pixels[+i * 4 + 2] = color.dmc_rgb[2];
          pixels[+i * 4 + 3] = 255;
        })
      })

      // initial load
      if (!this.resultCtx) {
        var canvas = document.getElementById("result"); // load context of canvas
        canvas.width = this.imageWidth;
        canvas.height = canvas.width * (this.imageHeight / this.imageWidth);
        this.resultCtx = canvas.getContext('2d'); // load context of canvas
      }

      var img = new ImageData(new Uint8ClampedArray(pixels), this.imageWidth, this.imageHeight);
      this.resultCtx.putImageData(img, 0, 0);
    },
    plotResult(color, idx) {
      this.$nextTick(function() {
        let pixels = new Array(this.simplifiedImagePixels.length * 4).fill(0);

        color.idx.forEach(i => {
          pixels[+i * 4] = color.dmc_rgb[0];
          pixels[+i * 4 + 1] = color.dmc_rgb[1];
          pixels[+i * 4 + 2] = color.dmc_rgb[2];
          pixels[+i * 4 + 3] = 255;
        })

        var canvas = document.getElementById(`result${idx}`); // load context of canvas
        if (this.maxScreenWidth > 1000) {
          canvas.width = this.maxScreenWidth * 0.25;
        } else if (this.maxScreenWidth > 500) {
          canvas.width = this.maxScreenWidth * 0.45;
        } else {
          canvas.width = this.maxScreenWidth * 0.95;
        }
        canvas.height = canvas.width * (this.imageHeight / this.imageWidth);

        var img = new ImageData(new Uint8ClampedArray(pixels), this.imageWidth, this.imageHeight)

        // generate a second canvas as a temp canvas to render the full pixel version
        var renderer = document.createElement('canvas');
        renderer.width = img.width;
        renderer.height = img.height;
        // render our ImageData on this canvas
        renderer.getContext('2d').putImageData(img, 0, 0);

        // render the scaled version on the real canvas.
        var ctx = canvas.getContext('2d'); // load context of canvas
        ctx.drawImage(renderer, 0, 0, canvas.width, canvas.height);
      });
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
td {
    padding: 0.25rem 0.5rem;
}

.input-num-colors {
    width: 225px;
}

.disabled {
    pointer-events: none;
    background: rgba(0, 0, 0, 0.12);
    color: rgba(0, 0, 0, 0.26);
    border-color: rgba(0, 0, 0, 0.26);
}

.w-400px {
    width: 400px;
}

@media (max-width: 420px) {
    .w-400px {
        width: 200px;
    }
}

.fa-lg {
    font-size: 1rem;
}

.fa-sm {
    font-size: 0.85rem;
}

.btn-outline-secondary {
    background: none !important;
    &:hover {
        background: #aaa !important;
    }
}

canvas {
    border: 1px solid #555;
}

#range {
    transform: rotateY(180deg);
}
</style>
