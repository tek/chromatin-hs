module Chromatin.Data.Chromatin where

import Ribosome.Orphans ()

import Chromatin.Data.Env (Env)
import Chromatin.Data.Error (Error)

type Chromatin a = Ribo Env Error a
